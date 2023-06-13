#!/usr/bin/python3

# this script will send event notifacations to the datadog server in the cloud.  

import requests
import json

# Set the event parameters
event_type = "my_event_type"
title = "My event title"
description = "My event description"
tags = ["tag1", "tag2"]
priority = "normal"

# Set the Datadog API key and application key
api_key = "your_api_key"
app_key = "your_application_key"

# Create the event payload
payload = {
    "title": title,
    "text": description,
    "priority": priority,
    "tags": tags,
    "alert_type": event_type
}

# Send the event to Datadog
url = "https://api.datadoghq.com/api/v1/events"
headers = {"Content-Type": "application/json", "DD-API-KEY": api_key, "DD-APPLICATION-KEY": app_key}
response = requests.post(url, headers=headers, data=json.dumps(payload))

# Check the response from Datadog
if response.status_code == requests.codes.ok:
    print("Event sent successfully.")
else:
    print("Failed to send event: {}".format(response.content))
