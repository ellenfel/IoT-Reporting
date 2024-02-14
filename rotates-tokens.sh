#!/bin/bash

# Your logic to generate the JWT token
# Replace the following line with your actual token generation logic
response=$(curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"username":"tenant@thingsboard.org", "password":"tenant"}' 'http://127.0.0.1:8080/api/auth/login')

# Extract the JWT token from the response
JWT_TOKEN=$(echo "$response" | jq -r '.token')

# Print the token
echo $JWT_TOKENzzzZ