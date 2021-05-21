#!/usr/bin/env python

import os

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

# Install the Slack app and get xoxb- token in advance
app = App(token=os.environ["SLACK_BOT_TOKEN"])

SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"]).connect()
if os.environ["BLOCKS"]:
    app.client.chat_postMessage(token=os.environ["SLACK_BOT_TOKEN"],
                                channel=os.environ["CHANNEL_ID"],
                                text=os.environ["MESSAGE"],
                                blocks=os.environ["BLOCKS"],
                                attachments=os.environ["ATTACHMENTS"])
else:
    app.client.chat_postMessage(token=os.environ["SLACK_BOT_TOKEN"],
                                channel=os.environ["CHANNEL_ID"],
                                attachments=os.environ["ATTACHMENTS"],
                                text=os.environ["MESSAGE"])
SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"]).close()
