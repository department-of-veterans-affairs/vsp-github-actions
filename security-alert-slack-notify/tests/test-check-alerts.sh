#!/usr/bin/env bash
#
# test-check-alerts.sh
#
# Local test harness for check-alerts.sh. Mocks the GitHub API responses
# and GHA environment variables, then runs the real script and displays
# the resulting Slack Block Kit payload.
#
# Usage:
#   ./test-check-alerts.sh [scenario]
#
# Scenarios:
#   alerts    - Mixed alerts across all three types (default)
#   clean     - No open alerts (all clear)
#   error     - Secret scanning returns an API error
#   partial   - Only code_scanning enabled
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REAL_SCRIPT="${SCRIPT_DIR}/../scripts/check-alerts.sh"

SCENARIO="${1:-alerts}"
TMPDIR_TEST=$(mktemp -d)
MOCK_SERVER_PID=""

cleanup() {
  [ -n "$MOCK_SERVER_PID" ] && kill "$MOCK_SERVER_PID" 2>/dev/null || true
  rm -rf "$TMPDIR_TEST"
}
trap cleanup EXIT

# ── Mock API data ────────────────────────────────────────────────────────────

MOCK_CODE_SCANNING='[
  {
    "number": 42,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/code-scanning/42",
    "rule": {
      "id": "js/sql-injection",
      "name": "js/sql-injection",
      "severity": "error",
      "security_severity_level": "critical",
      "description": "Building a SQL query from user-controlled sources is vulnerable to injection."
    },
    "tool": { "name": "CodeQL", "version": "2.19.3" }
  },
  {
    "number": 43,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/code-scanning/43",
    "rule": {
      "id": "js/xss-through-dom",
      "name": "js/xss-through-dom",
      "severity": "warning",
      "security_severity_level": "high",
      "description": "Rewriting the HTML of a DOM element using a user-controlled value."
    },
    "tool": { "name": "CodeQL", "version": "2.19.3" }
  },
  {
    "number": 44,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/code-scanning/44",
    "rule": {
      "id": "js/incomplete-url-scheme-check",
      "name": "js/incomplete-url-scheme-check",
      "severity": "warning",
      "security_severity_level": "medium",
      "description": "Checking for http: without https: is indicative of a bypassable security check."
    },
    "tool": { "name": "CodeQL", "version": "2.19.3" }
  }
]'

MOCK_SECRET_SCANNING='[
  {
    "number": 7,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/secret-scanning/7",
    "secret_type": "github_personal_access_token",
    "secret_type_display_name": "GitHub Personal Access Token",
    "validity": "active"
  },
  {
    "number": 8,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/secret-scanning/8",
    "secret_type": "aws_access_key_id",
    "secret_type_display_name": "AWS Access Key ID",
    "validity": "unknown"
  },
  {
    "number": 9,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/secret-scanning/9",
    "secret_type": "slack_incoming_webhook_url",
    "secret_type_display_name": "Slack Incoming Webhook URL",
    "validity": "inactive"
  }
]'

MOCK_DEPENDABOT='[
  {
    "number": 15,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/dependabot/15",
    "security_advisory": {
      "ghsa_id": "GHSA-9c47-m6qq-7p4h",
      "summary": "Prototype Pollution in JSON5 via Parse Method",
      "severity": "high"
    },
    "security_vulnerability": {
      "package": { "ecosystem": "npm", "name": "json5" },
      "severity": "high",
      "vulnerable_version_range": "< 2.2.2",
      "first_patched_version": { "identifier": "2.2.2" }
    }
  },
  {
    "number": 22,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/dependabot/22",
    "security_advisory": {
      "ghsa_id": "GHSA-wr3j-pwj9-hqq6",
      "summary": "Path traversal vulnerability in webpack-dev-middleware",
      "severity": "critical"
    },
    "security_vulnerability": {
      "package": { "ecosystem": "npm", "name": "webpack-dev-middleware" },
      "severity": "critical",
      "vulnerable_version_range": ">= 6.0.0, < 6.1.2",
      "first_patched_version": { "identifier": "6.1.2" }
    }
  },
  {
    "number": 31,
    "state": "open",
    "html_url": "https://github.com/department-of-veterans-affairs/vets-api/security/dependabot/31",
    "security_advisory": {
      "ghsa_id": "GHSA-c2qf-rxjj-qqgw",
      "summary": "semver vulnerable to Regular Expression Denial of Service",
      "severity": "low"
    },
    "security_vulnerability": {
      "package": { "ecosystem": "npm", "name": "semver" },
      "severity": "low",
      "vulnerable_version_range": "< 7.5.2",
      "first_patched_version": { "identifier": "7.5.2" }
    }
  }
]'

MOCK_EMPTY='[]'

MOCK_ERROR='{"message":"Resource not accessible by integration","documentation_url":"https://docs.github.com/rest"}'

# ── Mock HTTP server using a curl wrapper ────────────────────────────────────
#
# Instead of a real HTTP server, we replace curl with a shell function that
# returns mock data based on the URL pattern.

MOCK_CURL="${TMPDIR_TEST}/curl"

case "$SCENARIO" in
  alerts)
    echo "=== Scenario: Mixed alerts across all three types ==="
    ALERT_TYPES="code_scanning,secret_scanning,dependabot"
    cat > "$MOCK_CURL" << 'CURLEOF'
#!/usr/bin/env bash
# Mock curl — parse URL from args and return mock data
url=""
for arg in "$@"; do
  if [[ "$arg" == http* ]]; then
    url="$arg"
  fi
done
CURLEOF
    cat >> "$MOCK_CURL" << CURLEOF
if [[ "\$url" == *"code-scanning"* ]]; then
  echo '${MOCK_CODE_SCANNING}'
elif [[ "\$url" == *"secret-scanning"* ]]; then
  echo '${MOCK_SECRET_SCANNING}'
elif [[ "\$url" == *"dependabot"* ]]; then
  echo '${MOCK_DEPENDABOT}'
else
  echo '[]'
fi
CURLEOF
    ;;

  clean)
    echo "=== Scenario: No open alerts (all clear) ==="
    ALERT_TYPES="code_scanning,secret_scanning,dependabot"
    cat > "$MOCK_CURL" << 'CURLEOF'
#!/usr/bin/env bash
echo '[]'
CURLEOF
    ;;

  error)
    echo "=== Scenario: Secret scanning returns API error ==="
    ALERT_TYPES="code_scanning,secret_scanning,dependabot"
    cat > "$MOCK_CURL" << 'CURLEOF'
#!/usr/bin/env bash
url=""
for arg in "$@"; do
  if [[ "$arg" == http* ]]; then
    url="$arg"
  fi
done
CURLEOF
    cat >> "$MOCK_CURL" << CURLEOF
if [[ "\$url" == *"code-scanning"* ]]; then
  echo '${MOCK_CODE_SCANNING}'
elif [[ "\$url" == *"secret-scanning"* ]]; then
  echo '${MOCK_ERROR}'
elif [[ "\$url" == *"dependabot"* ]]; then
  echo '${MOCK_DEPENDABOT}'
else
  echo '[]'
fi
CURLEOF
    ;;

  partial)
    echo "=== Scenario: Only code_scanning enabled ==="
    ALERT_TYPES="code_scanning"
    cat > "$MOCK_CURL" << 'CURLEOF'
#!/usr/bin/env bash
url=""
for arg in "$@"; do
  if [[ "$arg" == http* ]]; then
    url="$arg"
  fi
done
CURLEOF
    cat >> "$MOCK_CURL" << CURLEOF
if [[ "\$url" == *"code-scanning"* ]]; then
  echo '${MOCK_CODE_SCANNING}'
else
  echo '[]'
fi
CURLEOF
    ;;

  *)
    echo "Unknown scenario: $SCENARIO"
    echo "Available: alerts, clean, error, partial"
    exit 1
    ;;
esac

chmod +x "$MOCK_CURL"

# ── Set up mock GHA environment ──────────────────────────────────────────────

GITHUB_ENV="${TMPDIR_TEST}/github_env"
touch "$GITHUB_ENV"

export GITHUB_REPOSITORY="department-of-veterans-affairs/vets-api"
export GITHUB_API_URL="https://api.github.com"
export GITHUB_SERVER_URL="https://github.com"
export GITHUB_ENV
export GH_TOKEN="mock-token-not-real"
export ALERT_TYPES
export PATH="${TMPDIR_TEST}:${PATH}"

# ── Run the real script ──────────────────────────────────────────────────────

echo ""
echo "Running check-alerts.sh..."
echo "─────────────────────────────────────────────────────────"
bash "$REAL_SCRIPT"
echo "─────────────────────────────────────────────────────────"

# ── Display results ──────────────────────────────────────────────────────────

echo ""
echo "=== GITHUB_ENV contents ==="
cat "$GITHUB_ENV"

echo ""
echo "=== Formatted SLACK_BLOCKS (pretty-printed) ==="
# Extract the blocks value from GITHUB_ENV (heredoc format)
BLOCKS_JSON=$(sed -n '/^SLACK_BLOCKS<<SLACKEOF$/,/^SLACKEOF$/{ /SLACKEOF/d; /SLACK_BLOCKS/d; p; }' "$GITHUB_ENV")

if command -v jq &> /dev/null; then
  echo "$BLOCKS_JSON" | jq .
else
  echo "$BLOCKS_JSON"
fi

echo ""
echo "=== SLACK_FALLBACK_TEXT ==="
grep "^SLACK_FALLBACK_TEXT=" "$GITHUB_ENV" | sed 's/^SLACK_FALLBACK_TEXT=//'
