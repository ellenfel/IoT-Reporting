#!/bin/bash

# Read the JWT token from the local text file
YOUR_JWT_TOKEN=$(cat /home/ellenfel/Desktop/reporting/jwt_token.txt)

while true; do
  # Renew the JWT token once an hour
  if [ $((SECONDS % 3600)) -eq 0 ]; then
    # Execute renew_token.sh to renew the token
    bash /home/ellenfel/Desktop/reporting/renew_token.sh
    # Read the renewed JWT token from the local text file
    YOUR_JWT_TOKEN=$(cat /home/ellenfel/Desktop/reporting/jwt_token.txt)
    echo "JWT token renewed: $YOUR_JWT_TOKEN" 
    fi

  sleep 15

  # Execute the GET request and store the response in a variable
  response=$(curl -X 'GET' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power' \
  -H 'accept: application/json' \
  -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
  )

  # Parse the JSON response and extract the value
  value=$(echo "$response" | jq -r '.power[0].value')

  # Check if the value is equal to "450"
  if [ "$value" = "450" ]; then
    # If the value is 450, execute the sql-script.sh script with sudo
    
    #sudo bash /home/ellenfel/Desktop/reporting/sql-script.sh
    sudo bash /home/ellenfel/Desktop/reporting/monthly-script.sh

    # Sleep for 15 seconds
    sleep 15

    # Execute the POST request
    response1=$(curl -X 'POST' \
    'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/timeseries/ANY?scope=ANY' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "X-Authorization: Bearer $YOUR_JWT_TOKEN" \
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
