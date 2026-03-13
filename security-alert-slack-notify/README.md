## Security Alert Slack Notify

Queries GitHub Advanced Security alerts (code scanning, secret scanning, dependabot) for the current repository and posts a formatted summary to a Slack channel using [`slackapi/slack-github-action@v2`](https://github.com/slackapi/slack-github-action).

Designed for scheduled workflows so Platform Support has consistent visibility into open security alerts across all Platform repos.

### Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| github_token | String | Token with `security-events:read` scope for GitHub API calls | | Y |
| slack_bot_token | String | Slack bot token (`xoxb-`) for posting messages | | Y |
| channel_id | String | Slack channel ID to post to | | Y |
| alert_types | String | Comma-separated alert types to check | `code_scanning,secret_scanning,dependabot` | N |

### Token Permissions

The workflow calling this action needs the following `permissions`:

```yaml
permissions:
  contents: read
  security-events: read
```

**Important:** The default `GITHUB_TOKEN` (`secrets.GITHUB_TOKEN`) provides access to code scanning alerts with `security-events: read`. However, secret scanning and dependabot alert APIs may require a GitHub App token or PAT with additional scopes (`secret_scanning_alerts: read`, `vulnerability_alerts: read`). Test with your repository's token configuration to confirm which alert types are accessible.

### Slack Message Format

When alerts exist, the message includes:
- Header with repository name
- Overview counts for each alert type
- Severity breakdown for code scanning and dependabot (critical, high, medium, low)
- Secret type breakdown for secret scanning (top 5 types by count)
- Direct links to the repository's security dashboard

When no alerts are open, a clean "all clear" confirmation is posted.

If an alert type's API returns an error (e.g., insufficient token permissions), the overview shows a warning indicator for that type rather than failing the entire action.

### Usage

Add a workflow to your repository that runs on a schedule. The AWS credentials and SSM steps follow the patterns already in use in each source repo — adapt to match your repo's existing credential pattern.

```yaml
name: Security Alert Notifications

on:
  schedule:
    - cron: '17 13 * * 1-5'  # Weekdays ~9:17 AM ET
    - cron: '47 19 * * 1-5'  # Weekdays ~3:47 PM ET
  workflow_dispatch:

permissions:
  id-token: write
  contents: read
  security-events: read

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: ./.github/workflows/configure-aws-credentials
        with:
          role: ${{ vars.AWS_ASSUME_ROLE }}

      - name: Get Slack bot token
        uses: department-of-veterans-affairs/action-inject-ssm-secrets@latest
        with:
          ssm_parameter: /devops/github_actions_slack_bot_user_token
          env_variable_name: SLACK_BOT_TOKEN

      - name: Check and notify security alerts
        uses: department-of-veterans-affairs/vsp-github-actions/security-alert-slack-notify@main
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          slack_bot_token: ${{ env.SLACK_BOT_TOKEN }}
          channel_id: 'CXXXXXXXX'
          alert_types: 'code_scanning,secret_scanning,dependabot'
```

### Checking only specific alert types

```yaml
      - name: Check code scanning only
        uses: department-of-veterans-affairs/vsp-github-actions/security-alert-slack-notify@main
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          slack_bot_token: ${{ env.SLACK_BOT_TOKEN }}
          channel_id: 'CXXXXXXXX'
          alert_types: 'code_scanning'
```

### Limitations

- **Pagination:** Each alert type fetches up to 100 open alerts per API call. Repositories with more than 100 open alerts of a single type will see a capped count. Pagination can be added if needed.
- **GHEC-US:** The action uses `GITHUB_API_URL` and `GITHUB_SERVER_URL` environment variables, which should automatically resolve to the correct API endpoints on `va.ghe.com` after migration.
