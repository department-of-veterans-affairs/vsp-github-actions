## Security Alert Slack Notify

Queries GitHub Advanced Security alerts (code scanning, secret scanning, dependabot) for the current repository and posts a formatted summary to a Slack channel via [Socket Mode](../slack-socket/README.md).

Designed for scheduled workflows so Platform Support has consistent visibility into open security alerts across all Platform repos.

### Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| github-token | String | Token with `security-events:read` scope for GitHub API calls | | Y |
| slack-app-token | String | Slack App Token (`xapp-`) for Socket Mode connection | | Y |
| slack-bot-token | String | Slack Bot User Token (`xoxb-`) for posting messages | | Y |
| channel-id | String | Slack channel ID to post the alert summary to | | Y |
| alert-types | String | Comma-separated alert types to check | `code_scanning,secret_scanning,dependabot` | N |

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

Add a workflow to your repository that runs on a schedule:

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

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-gov-west-1

      - name: Get Slack app token
        uses: department-of-veterans-affairs/action-inject-ssm-secrets@latest
        with:
          ssm_parameter: /devops/github_actions_slack_socket_token
          env_variable_name: SLACK_APP_TOKEN

      - name: Get Slack bot token
        uses: department-of-veterans-affairs/action-inject-ssm-secrets@latest
        with:
          ssm_parameter: /devops/github_actions_slack_bot_user_token
          env_variable_name: SLACK_BOT_TOKEN

      - name: Check and notify security alerts
        uses: department-of-veterans-affairs/vsp-github-actions/security-alert-slack-notify@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          slack-app-token: ${{ env.SLACK_APP_TOKEN }}
          slack-bot-token: ${{ env.SLACK_BOT_TOKEN }}
          channel-id: 'CXXXXXXXX'
```

### Checking only specific alert types

```yaml
      - name: Check code scanning only
        uses: department-of-veterans-affairs/vsp-github-actions/security-alert-slack-notify@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          slack-app-token: ${{ env.SLACK_APP_TOKEN }}
          slack-bot-token: ${{ env.SLACK_BOT_TOKEN }}
          channel-id: 'CXXXXXXXX'
          alert-types: 'code_scanning'
```

### Limitations

- **Pagination:** Each alert type fetches up to 100 open alerts per API call. Repositories with more than 100 open alerts of a single type will see a capped count. Pagination can be added if needed.
- **GHEC-US:** The action uses `GITHUB_API_URL` and `GITHUB_SERVER_URL` environment variables, which should automatically resolve to the correct API endpoints on `va.ghe.com` after migration.
