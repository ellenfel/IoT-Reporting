#!/bin/bash

# Function to refresh the JWT token

JWT_TOKEN="eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ0ZW5hbnRAdGhpbmdzYm9hcmQub3JnIiwidXNlcklkIjoiZDc2MDlkMTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5Iiwic2NvcGVzIjpbIlRFTkFOVF9BRE1JTiJdLCJzZXNzaW9uSWQiOiJmODFkYjFmZi01ZDA4LTQyZWItYWQ0Ny04YTQ0N2NhNmFhZmUiLCJpc3MiOiJ0aGluZ3Nib2FyZC5pbyIsImlhdCI6MTcwODQyMDI3NywiZXhwIjoxNzA4NDI5Mjc3LCJlbmFibGVkIjp0cnVlLCJpc1B1YmxpYyI6ZmFsc2UsInRlbmFudElkIjoiZDcyZmM5MTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5IiwiY3VzdG9tZXJJZCI6IjEzODE0MDAwLTFkZDItMTFiMi04MDgwLTgwODA4MDgwODA4MCJ9.r0bivAVqDzWre0pl-JbvKHPxa9Gh8N-yutMxEz5A5qSCSHWiXgo-Bj_iUKTbuQ7Ag_pB9qqdtuYWV_RB2PDAgQ"


#echo "$JWT_TOKEN" > /home/ellenfel/Desktop/reporting/jwt_token.txt


response=$(curl -X 'GET' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power' \
  -H 'accept: application/json' \
  -H "X-Authorization: Bearer $JWT_TOKEN"
)


echo "Response: $response"

#echo "$NEW_TOKEN" > /home/ellenfel/Desktop/reporting/jwt_token.txt



