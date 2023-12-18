#!/bin/bash

# Function to refresh the JWT token

JWT_TOKEN="Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJ0ZW5hbnRAdGhpbmdzYm9hcmQub3JnIiwidXNlcklkIjoiZDc2MDlkMTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5Iiwic2NvcGVzIjpbIlRFTkFOVF9BRE1JTiJdLCJzZXNzaW9uSWQiOiI4YmYxNjc0ZC0wYWM3LTRkZDktOWQ5MC02ODZlMDNhMTFlMzMiLCJpc3MiOiJ0aGluZ3Nib2FyZC5pbyIsImlhdCI6MTcwMjg4NzMzMCwiZXhwIjoxNzAyODk2MzMwLCJlbmFibGVkIjp0cnVlLCJpc1B1YmxpYyI6ZmFsc2UsInRlbmFudElkIjoiZDcyZmM5MTAtMWMxOC0xMWVlLTkyMGYtZmYzYjJiYTAyNmE5IiwiY3VzdG9tZXJJZCI6IjEzODE0MDAwLTFkZDItMTFiMi04MDgwLTgwODA4MDgwODA4MCJ9.81hTf6NbGYMkaIk5xwIozXUl4b6sV27Z0xYkAQU1idybqp6W5MJezIJF4-thonN7bLHZtZHx1Or3RD3dmxvLFA"
response=$(curl -X 'GET' \
  'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/45aec080-2600-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power' \
  -H 'accept: application/json' \
  -H "X-Authorization: Bearer $JWT_TOKEN"
)

echo "Response: $response"


