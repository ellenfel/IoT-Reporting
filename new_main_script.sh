#!/bin/bash

# Read the JWT token from the local text file
bash /home/nemport/IoT-Reporting/renew_token.sh
YOUR_JWT_TOKEN=$(cat /home/nemport/IoT-Reporting/jwt_token.txt)

while true; do
  # Renew the JWT token once an hour
  if [ $((SECONDS % 3500)) -eq 0 ]; then
    # Execute renew_token.sh to renew the token
    /home/nemport/IoT-Reporting/renew_token.sh
    # Read the renewed JWT token from the local text file
    YOUR_JWT_TOKEN=$(cat /home/nemport/IoT-Reporting/jwt_token.txt)
    echo "JWT token renewed: $YOUR_JWT_TOKEN"
  fi


  #Flag
  # Execute the GET request and store the response in a variable / this should be the flag to gen report or not
  response=$(curl -X 'GET' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/87fc84a0-41c5-11ee-a5d9-5d300dfdbc78/values/timeseries?keys=key' \
  -H 'accept: application/json' \
  -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
  )

  # Parse the JSON response and extract the value {input 1}
  value=$(echo "$response" | jq -r '.key[0].value')

  # Check if the value is equal to "450"
  if [ "$value" = "450" ]; then

  #IS IT MONTHLY        {input 2}
    
    #MONTH - YEAR       {input 2.1}
      #Script-1

  #IS IT DAIYLY         {input 3}

    #MONTH - DAY - YEAR {input 3.1}
      #Script-2

    # If the value is 450, execute the sql-script.sh script with sudo
    sudo bash <dir>/sql-script.sh #(delete-this)

    # Sleep for 15 seconds
    sleep 15

    #(this should be with-in if-else)
    # Execute the POST request
    response1=$(curl -X 'POST' \
    'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/87fc84a0-41c5-11ee-a5d9-5d300dfdbc78/values/timeseries/ANY?scope=ANY' \
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

