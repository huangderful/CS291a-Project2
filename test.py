import requests
import json

url = "https://fyxic8g92i.execute-api.us-west-2.amazonaws.com/prod//auth/token"  # Replace with your actual URL

# Set the headers
headers = {"Content-Type": "application/json"}

# Send the request with an empty JSON object
response = requests.post(url, headers=headers, json=1)

print(response.status_code)  # Check the response code
print(response.content) 