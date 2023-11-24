#!/bin/bash

# Function to refresh the JWT token

JWT_TOKEN="eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ0ZW5hbnRAdGhpbmdzYm9hcmQub3JnIiwidXNlcklkIjoiZDc2MDlkMTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5Iiwic2NvcGVzIjpbIlRFTkFOVF9BRE1JTiJdLCJzZXNzaW9uSWQiOiJlYjJmNmNkMS05OWQxLTQxYWItODMyNC1lYjBjYWM0NTUxYWMiLCJpc3MiOiJ0aGluZ3Nib2FyZC5pbyIsImlhdCI6MTY5NjU4ODUzNiwiZXhwIjoxNjk2NTk3NTM2LCJlbmFibGVkIjp0cnVlLCJpc1B1YmxpYyI6ZmFsc2UsInRlbmFudElkIjoiZDcyZmM5MTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5IiwiY3VzdG9tZXJJZCI6IjEzODE0MDAwLTFkZDItMTFiMi04MDgwLTgwODA4MDgwODA4MCJ9.BoVYxgDs4qQp7Lh18KxXI_XzqIS-D8APcpJF1HEJxdw79qoZCMXlARll33Df_AI9-rdrmvEqzSPWhIsAg7up6Q"

response=$(curl -X 'GET' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/45aec080-2600-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power' \
  -H 'accept: application/json' \
  -H "X-Authorization: Bearer $JWT_TOKEN"
)

echo "Response: $response"



