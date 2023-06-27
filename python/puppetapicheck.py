#!/usr/bin/python3

# script that uses functions to check to see if puppet is working ok from an agent node

import requests  # allows you to send HTTP requests using Python
import json      # does serialization of encoding data into JSON format

def puppet_check():
    try:
        # Run the "sudo puppet agent -t" command
        # and capture the output
        output = subprocess.check_output(["sudo", "puppet", "agent", "-t"])
        
        # If the output contains this string,
        # the Puppet run was successful
        if "Applied catalog" in output.decode():
            print("Puppet run successful!")
        else:
            # If the output does NOT contain the "Applied catalog" string,
            # raise an exception to be handled by the calling code
            raise Exception("Puppet run failed.")
    except subprocess.CalledProcessError as e:
        # If the Puppet command itself throws an error,
        # raise an exception to be handled by the calling code
        raise Exception("Error running Puppet command: {}".format(e))

def datadog_call():
    # Make an API call to Datadog
    datadog_url = "https://api.datadoghq.com/api/v1/events"
    headers = {"Content-Type": "application/json"}
    payload = {
        "title": "Puppet run failed",
        "text": "The Puppet run failed on the following host",
        "priority": "normal",
        "tags": ["puppet", "error", "datadog"]
    }
    response = requests.post(datadog_url, headers=headers, json=payload)
    if response.status_code == 200:
        print("Datadog call successful!")
    else:
        raise Exception("Error calling Datadog API: {}".format(response.content))

# Now, you can call these functions in order to run the Puppet check and make the Datadog API call if needed:
try:
    puppet_check()
except Exception as e:
    print("Puppet check failed: {}".format(e))
    datadog_call()
