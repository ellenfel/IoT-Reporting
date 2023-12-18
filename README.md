# reporting-IosPhere

curl -X 'GET'   'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power'   -H 'accept: application/json'   -H 'X-Authorization: Bearer $YOUR_JWT_TOKEN'


1 - get-token.sh  -> after executed outputs following:                      
        {"token":"$YOUR_JWT_TOKEN", "refreshToken":"$YOUR_JWT_REFRESH_TOKEN"}

2 - get-tel.sh -> check for user inputs, should work as a microservice
        once trigerred it executes sql-script.sh 
        It should take new jwt token as a input 

3 - sql-script.sh -> executes a sql script & generates the report as csv
        This shoul also take user input key and device primarilly


pseudo codes:
get-token.sh

curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"username":"mail@mail.com", "password":"password"}' 'http://URL/api/auth/login'


get-tel.sh


while true; do
  # Execute the GET request and store the response in a variable
  response=$(curl -X 'GET' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/DEVICE_id/values/timeseries?keys=key' \
  -H 'accept: application/json' \
  -H 'X-Authorization: Bearer $YOUR_JWT_TOKEN'
)

  # Parse the JSON response and extract the value
  value=$(echo "$response" | jq -r '.key[0].value')

  # Check if the value is equal to "450"
  if [ "$value" = "450" ]; then
    # If the value is 450, execute the sql-script.sh script with sudo
    sudo bash <dir>/sql-script.sh

    # Sleep for 15 seconds
    sleep 15

    # Execute the POST request
    response1=$(curl -X 'POST' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/DEVICE_id/values/timeseries/ANY?scope=ANY' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'X-Authorization: Bearer $YOUR_JWT_TOKEN'\
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