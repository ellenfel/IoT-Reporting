bash /home/ellenfel/Desktop/reporting/renew_token.sh
YOUR_JWT_TOKEN=$(cat /home/ellenfel/Desktop/reporting/jwt_token.txt)



while true; do
    # Renew the JWT token once an hour
    if [ $((SECONDS % 3500)) -eq 0 ]; then
        # Execute renew_token.sh to renew the token
        /home/ellenfel/Desktop/reporting/renew_token.sh
        # Read the renewed JWT token from the local text file
        YOUR_JWT_TOKEN=$(cat /home/ellenfel/Desktop/reporting/jwt_token.txt)
        echo "JWT token renewed: $YOUR_JWT_TOKEN"
    fi

    sleep 15



    #Flag - first input

    response_flag=$(curl -X 'GET' \
    'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=reportFlag' \
    -H 'accept: application/json' \
    -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
    )

    reportFlag=$(echo "$response_flag" | jq -r '.[0].value')


    if [ "$reportFlag" = "false" ]; then
        # If the value is 450, execute the sql-script.sh script with sudo
            
        echo condition-returns_false 
        sleep 1


    else
        # If the value is not 450, sleep for 5 seconds and then try again
        echo error!!!!!
        sleep 1 
    fi



    # Execute the GET request and store the response in a variable / Ts
    response=$(curl -X 'GET' \
    'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power' \
    -H 'accept: application/json' \
    -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
    )

    # Parse the JSON response and extract the value {input 1 & 2}
    value=$(echo "$response" | jq -r '.power[0].value')



    echo $value
    echo $reportFlag

done