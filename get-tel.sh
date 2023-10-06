#!/bin/bash

while true; do
  # Execute the GET request and store the response in a variable
  response=$(curl -X 'GET' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power' \
  -H 'accept: application/json' \
  -H 'X-Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ0ZW5hbnRAdGhpbmdzYm9hcmQub3JnIiwidXNlcklkIjoiZDc2MDlkMTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5Iiwic2NvcGVzIjpbIlRFTkFOVF9BRE1JTiJdLCJzZXNzaW9uSWQiOiI4MmY1YzM5NC03ZTc0LTQ4ZTctODk0MS05MWQyM2U1YTQ3ZTgiLCJpc3MiOiJ0aGluZ3Nib2FyZC5pbyIsImlhdCI6MTY5NjQ4NjE1NSwiZXhwIjoxNjk2NDk1MTU1LCJlbmFibGVkIjp0cnVlLCJpc1B1YmxpYyI6ZmFsc2UsInRlbmFudElkIjoiZDcyZmM5MTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5IiwiY3VzdG9tZXJJZCI6IjEzODE0MDAwLTFkZDItMTFiMi04MDgwLTgwODA4MDgwODA4MCJ9.K_AUlSxuZqafI1R58IKG_BRzaK-3te8yg4MlFbA6S9pj34I_MoILs93J8ffBBSOXocWEnfXvnQ4NH3YZm96czQ'
)

  # Parse the JSON response and extract the value
  value=$(echo "$response" | jq -r '.power[0].value')

  # Check if the value is equal to "450"
  if [ "$value" = "450" ]; then
    # If the value is 450, execute the a.sh script with sudo
    sudo bash /home/ellenfel/Desktop/reporting/sql-script.sh

    # Sleep for 15 seconds
    sleep 15

    # Execute the POST request
    response1=$(curl -X 'POST' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/timeseries/ANY?scope=ANY' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ0ZW5hbnRAdGhpbmdzYm9hcmQub3JnIiwidXNlcklkIjoiZDc2MDlkMTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5Iiwic2NvcGVzIjpbIlRFTkFOVF9BRE1JTiJdLCJzZXNzaW9uSWQiOiI4MmY1YzM5NC03ZTc0LTQ4ZTctODk0MS05MWQyM2U1YTQ3ZTgiLCJpc3MiOiJ0aGluZ3Nib2FyZC5pbyIsImlhdCI6MTY5NjQ4NjE1NSwiZXhwIjoxNjk2NDk1MTU1LCJlbmFibGVkIjp0cnVlLCJpc1B1YmxpYyI6ZmFsc2UsInRlbmFudElkIjoiZDcyZmM5MTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5IiwiY3VzdG9tZXJJZCI6IjEzODE0MDAwLTFkZDItMTFiMi04MDgwLTgwODA4MDgwODA4MCJ9.K_AUlSxuZqafI1R58IKG_BRzaK-3te8yg4MlFbA6S9pj34I_MoILs93J8ffBBSOXocWEnfXvnQ4NH3YZm96czQ' \
  -d '{
"power": 4500
}'
)

    echo "$response1"
    
  else
    # If the value is not 450, sleep for 5 seconds and then try again
    sleep 5
  fi
done

