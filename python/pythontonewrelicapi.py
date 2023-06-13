import requests
import json

headers = {
    'X-Api-Key': '<your-api-key>',
    'Content-Type': 'application/json',
}

payload = {
    "eventType": "MyCustomEventType",
    "description": "This is a test event",
    "details": {
        "key1": "value1",
        "key2": "value2"
    }
}

url = 'https://insights-collector.newrelic.com/v1/accounts/<your-account-id>/events'

response = requests.post(url, headers=headers, data=json.dumps(payload))

if response.status_code == requests.codes.ok:
    print("API call was successful!")
else:
    print(f"API call failed with status code: {response.status_code}")
