#!/bin/bash

# Path to the script that generates the JWT token
TOKEN_SCRIPT_PATH=/home/ellenfel/Desktop/reporting/rotates-tokens.sh

# Execute the script to generate a new token
NEW_TOKEN=$($TOKEN_SCRIPT_PATH)

# Update the configuration or environment variable with the new token
# Replace the following line with your actual logic to update the token
echo "Setting new token: $NEW_TOKEN"

# Store the new token in a local text file
echo "$NEW_TOKEN" > /home/ellenfel/Desktop/reporting/jwt_token.txt

# You might need to restart your main application or update a configuration file
# Example: Restart the main application
# systemctl restart your_application_service

# You can add additional logic here based on your requirements
