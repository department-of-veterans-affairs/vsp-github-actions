# Slack Message Send via Websockets Docker action

This action sends a message to Slack via a websocket.

## Inputs

### `slack_app_token`
**Required**
The slack token for your application

### `slack_bot_token`
**Required**
The slack token for your bot user

### `message`
**Required**
The message you wish to send, as a simple string

### `channel_id`
**Required**
The channel ID you wish to send your message to

### `blocks`
**Not Required**
A JSON string which represents the Slack Blocks you wish to send

### `attachments`
**Not Required**
A JSON string which represents the Slack Attachments you wish to send

## Example usage
```
uses: department-of-veterans-affairs/vsp-github-actions/slack-socket
with:
  slack_app_token: "xapp-xxxxx"
  slack_bot_token: "xoxb-xxxxx"
  message: "This is the message!"
  blocks: "[{\"type\": \"section\", \"text\": {\"type\": \"plain_text\", \"text\": \"Hello world\"}}]"
  channel_id: "XXXXXXX"
```
NOTE: Please note the escaped double quotes in the JSON string. If you choose to include "blocks", the received message will use the text in "message" as a fallback.
