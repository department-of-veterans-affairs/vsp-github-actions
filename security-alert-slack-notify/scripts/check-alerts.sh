#!/usr/bin/env bash
#
# check-alerts.sh
#
# Queries GitHub REST API for open security alerts (code scanning, secret
# scanning, dependabot) and builds a Slack Block Kit JSON payload.
#
# Required environment variables:
#   GH_TOKEN    - GitHub token with security-events:read scope
#   ALERT_TYPES - Comma-separated list: code_scanning,secret_scanning,dependabot
#
# Outputs (written to GITHUB_ENV):
#   SLACK_BLOCKS        - Block Kit JSON array for Slack message
#   SLACK_FALLBACK_TEXT - Plain-text fallback for notifications
#
set -euo pipefail

REPO="${GITHUB_REPOSITORY}"
API_BASE="${GITHUB_API_URL:-https://api.github.com}"
REPO_NAME="${REPO##*/}"
MAX_PER_PAGE=100

# ── Helpers ──────────────────────────────────────────────────────────────────

api_get() {
  local endpoint="$1"
  curl -sf \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${API_BASE}${endpoint}" 2>/dev/null || echo "[]"
}

json_length() {
  echo "$1" | jq 'if type == "array" then length else 0 end'
}

# Count occurrences of a value at a given jq path in a JSON array.
# Usage: count_by_field "$json" '.rule.security_severity_level' 'critical'
count_by_field() {
  local json="$1" path="$2" value="$3"
  echo "$json" | jq --arg v "$value" "[.[] | select(${path} == \$v)] | length"
}

# Check if a value exists in the TYPES array.
# Usage: has_type "code_scanning"
has_type() {
  local target="$1"
  for t in "${TYPES[@]}"; do
    [[ "$(echo "$t" | xargs)" == "$target" ]] && return 0
  done
  return 1
}

# ── Fetch alerts ─────────────────────────────────────────────────────────────

IFS=',' read -ra TYPES <<< "${ALERT_TYPES}"

CODE_SCANNING_JSON="[]"
SECRET_SCANNING_JSON="[]"
DEPENDABOT_JSON="[]"

CODE_SCANNING_COUNT=0
SECRET_SCANNING_COUNT=0
DEPENDABOT_COUNT=0

CODE_SCANNING_ERROR=""
SECRET_SCANNING_ERROR=""
DEPENDABOT_ERROR=""

for alert_type in "${TYPES[@]}"; do
  alert_type="$(echo "$alert_type" | xargs)" # trim whitespace
  case "$alert_type" in
    code_scanning)
      response=$(api_get "/repos/${REPO}/code-scanning/alerts?state=open&per_page=${MAX_PER_PAGE}")
      if echo "$response" | jq -e 'type == "array"' > /dev/null 2>&1; then
        CODE_SCANNING_JSON="$response"
        CODE_SCANNING_COUNT=$(json_length "$response")
      else
        CODE_SCANNING_ERROR="Unable to fetch code scanning alerts (check token permissions)"
      fi
      ;;
    secret_scanning)
      response=$(api_get "/repos/${REPO}/secret-scanning/alerts?state=open&per_page=${MAX_PER_PAGE}")
      if echo "$response" | jq -e 'type == "array"' > /dev/null 2>&1; then
        SECRET_SCANNING_JSON="$response"
        SECRET_SCANNING_COUNT=$(json_length "$response")
      else
        SECRET_SCANNING_ERROR="Unable to fetch secret scanning alerts (check token permissions)"
      fi
      ;;
    dependabot)
      response=$(api_get "/repos/${REPO}/dependabot/alerts?state=open&per_page=${MAX_PER_PAGE}")
      if echo "$response" | jq -e 'type == "array"' > /dev/null 2>&1; then
        DEPENDABOT_JSON="$response"
        DEPENDABOT_COUNT=$(json_length "$response")
      else
        DEPENDABOT_ERROR="Unable to fetch dependabot alerts (check token permissions)"
      fi
      ;;
    *)
      echo "::warning::Unknown alert type: ${alert_type}"
      ;;
  esac
done

TOTAL_ALERTS=$((CODE_SCANNING_COUNT + SECRET_SCANNING_COUNT + DEPENDABOT_COUNT))

# ── GitHub link helpers ──────────────────────────────────────────────────────

SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
SECURITY_URL="${SERVER_URL}/${REPO}/security"
CODE_SCANNING_URL="${SERVER_URL}/${REPO}/security/code-scanning"
SECRET_SCANNING_URL="${SERVER_URL}/${REPO}/security/secret-scanning"
DEPENDABOT_URL="${SERVER_URL}/${REPO}/security/dependabot"

# ── Build Slack blocks ───────────────────────────────────────────────────────

BLOCKS="["

# Header block
if [ "$TOTAL_ALERTS" -gt 0 ]; then
  BLOCKS+="{\"type\":\"header\",\"text\":{\"type\":\"plain_text\",\"text\":\":lock: Security Alert Summary \u2014 ${REPO_NAME}\",\"emoji\":true}},"
else
  BLOCKS+="{\"type\":\"header\",\"text\":{\"type\":\"plain_text\",\"text\":\":white_check_mark: Security Alert Summary \u2014 ${REPO_NAME}\",\"emoji\":true}},"
fi

# Overview section
if [ "$TOTAL_ALERTS" -eq 0 ] && [ -z "$CODE_SCANNING_ERROR" ] && [ -z "$SECRET_SCANNING_ERROR" ] && [ -z "$DEPENDABOT_ERROR" ]; then
  BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"No open security alerts. All clear! :tada:\"}},"
else
  overview_parts=()
  for alert_type in "${TYPES[@]}"; do
    alert_type="$(echo "$alert_type" | xargs)"
    case "$alert_type" in
      code_scanning)
        if [ -n "$CODE_SCANNING_ERROR" ]; then
          overview_parts+=("*Code Scanning:* :warning: error")
        else
          overview_parts+=("*Code Scanning:* ${CODE_SCANNING_COUNT}")
        fi
        ;;
      secret_scanning)
        if [ -n "$SECRET_SCANNING_ERROR" ]; then
          overview_parts+=("*Secret Scanning:* :warning: error")
        else
          overview_parts+=("*Secret Scanning:* ${SECRET_SCANNING_COUNT}")
        fi
        ;;
      dependabot)
        if [ -n "$DEPENDABOT_ERROR" ]; then
          overview_parts+=("*Dependabot:* :warning: error")
        else
          overview_parts+=("*Dependabot:* ${DEPENDABOT_COUNT}")
        fi
        ;;
    esac
  done

  overview_text=""
  for i in "${!overview_parts[@]}"; do
    [ "$i" -gt 0 ] && overview_text+=" | "
    overview_text+="${overview_parts[$i]}"
  done
  BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":bar_chart: *Overview:* ${overview_text}\"}},"
  BLOCKS+="{\"type\":\"divider\"},"
fi

# ── Code Scanning detail ────────────────────────────────────────────────────

if has_type "code_scanning"; then
  if [ -n "$CODE_SCANNING_ERROR" ]; then
    BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":warning: *Code Scanning* \u2014 ${CODE_SCANNING_ERROR}\"}},"
  elif [ "$CODE_SCANNING_COUNT" -gt 0 ]; then
    cs_critical=$(count_by_field "$CODE_SCANNING_JSON" '.rule.security_severity_level' 'critical')
    cs_high=$(count_by_field "$CODE_SCANNING_JSON" '.rule.security_severity_level' 'high')
    cs_medium=$(count_by_field "$CODE_SCANNING_JSON" '.rule.security_severity_level' 'medium')
    cs_low=$(count_by_field "$CODE_SCANNING_JSON" '.rule.security_severity_level' 'low')
    cs_other=$((CODE_SCANNING_COUNT - cs_critical - cs_high - cs_medium - cs_low))

    cs_text="*<${CODE_SCANNING_URL}|Code Scanning>* (${CODE_SCANNING_COUNT} open)\\n"
    [ "$cs_critical" -gt 0 ] && cs_text+=":red_circle: Critical: ${cs_critical}\\n" || true
    [ "$cs_high" -gt 0 ] && cs_text+=":large_orange_circle: High: ${cs_high}\\n" || true
    [ "$cs_medium" -gt 0 ] && cs_text+=":large_yellow_circle: Medium: ${cs_medium}\\n" || true
    [ "$cs_low" -gt 0 ] && cs_text+=":white_circle: Low: ${cs_low}\\n" || true
    [ "$cs_other" -gt 0 ] && cs_text+=":black_circle: Other/Unspecified: ${cs_other}\\n" || true

    BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"${cs_text}\"}},"
  fi
fi

# ── Secret Scanning detail ───────────────────────────────────────────────────

if has_type "secret_scanning"; then
  if [ -n "$SECRET_SCANNING_ERROR" ]; then
    BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":warning: *Secret Scanning* \u2014 ${SECRET_SCANNING_ERROR}\"}},"
  elif [ "$SECRET_SCANNING_COUNT" -gt 0 ]; then
    ss_text="*<${SECRET_SCANNING_URL}|Secret Scanning>* (${SECRET_SCANNING_COUNT} open)\\n"

    # List up to 5 individual secret types
    secret_types=$(echo "$SECRET_SCANNING_JSON" | jq -r '[.[].secret_type_display_name] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count) | .[:5][] | "\(.count)x \(.type)"')
    while IFS= read -r line; do
      [ -n "$line" ] && ss_text+=":warning: ${line}\\n" || true
    done <<< "$secret_types"

    remaining=$((SECRET_SCANNING_COUNT - $(echo "$SECRET_SCANNING_JSON" | jq '[.[].secret_type_display_name] | group_by(.) | map(length) | .[:5] | add // 0')))
    [ "$remaining" -gt 0 ] && ss_text+="_...and ${remaining} more_\\n" || true

    BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"${ss_text}\"}},"
  fi
fi

# ── Dependabot detail ────────────────────────────────────────────────────────

if has_type "dependabot"; then
  if [ -n "$DEPENDABOT_ERROR" ]; then
    BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":warning: *Dependabot* \u2014 ${DEPENDABOT_ERROR}\"}},"
  elif [ "$DEPENDABOT_COUNT" -gt 0 ]; then
    db_critical=$(count_by_field "$DEPENDABOT_JSON" '.security_vulnerability.severity' 'critical')
    db_high=$(count_by_field "$DEPENDABOT_JSON" '.security_vulnerability.severity' 'high')
    db_medium=$(count_by_field "$DEPENDABOT_JSON" '.security_vulnerability.severity' 'medium')
    db_low=$(count_by_field "$DEPENDABOT_JSON" '.security_vulnerability.severity' 'low')
    db_other=$((DEPENDABOT_COUNT - db_critical - db_high - db_medium - db_low))

    db_text="*<${DEPENDABOT_URL}|Dependabot>* (${DEPENDABOT_COUNT} open)\\n"
    [ "$db_critical" -gt 0 ] && db_text+=":red_circle: Critical: ${db_critical}\\n" || true
    [ "$db_high" -gt 0 ] && db_text+=":large_orange_circle: High: ${db_high}\\n" || true
    [ "$db_medium" -gt 0 ] && db_text+=":large_yellow_circle: Medium: ${db_medium}\\n" || true
    [ "$db_low" -gt 0 ] && db_text+=":white_circle: Low: ${db_low}\\n" || true
    [ "$db_other" -gt 0 ] && db_text+=":black_circle: Other/Unspecified: ${db_other}\\n" || true

    BLOCKS+="{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"${db_text}\"}},"
  fi
fi

# ── Footer with link to security dashboard ───────────────────────────────────

BLOCKS+="{\"type\":\"divider\"},"
BLOCKS+="{\"type\":\"context\",\"elements\":[{\"type\":\"mrkdwn\",\"text\":\":link: <${SECURITY_URL}|View full security dashboard>\"}]}"
BLOCKS+="]"

# ── Fallback text for notifications ──────────────────────────────────────────

if [ "$TOTAL_ALERTS" -eq 0 ]; then
  FALLBACK_TEXT="Security Alert Summary - ${REPO_NAME}: No open alerts. All clear!"
else
  FALLBACK_TEXT="Security Alert Summary - ${REPO_NAME}: ${TOTAL_ALERTS} open alert(s) - Code Scanning: ${CODE_SCANNING_COUNT}, Secret Scanning: ${SECRET_SCANNING_COUNT}, Dependabot: ${DEPENDABOT_COUNT}"
fi

# ── Write outputs to GITHUB_ENV ──────────────────────────────────────────────

{
  echo "SLACK_FALLBACK_TEXT=${FALLBACK_TEXT}"
  echo "SLACK_BLOCKS<<SLACKEOF"
  echo "${BLOCKS}"
  echo "SLACKEOF"
} >> "${GITHUB_ENV}"

echo "::notice::Total open alerts for ${REPO}: ${TOTAL_ALERTS}"
