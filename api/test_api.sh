#!/bin/bash

BASE_URL="http://linguallearn-alb-dev-91547010.us-east-1.elb.amazonaws.com"

echo "Testing health endpoint..."
curl -s "$BASE_URL/api/health" | jq .

echo -e "\n\nCreating test user..."
USER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@linguallearn.com",
    "username": "demouser",
    "password": "Demo123!",
    "role": "learner"
  }')

echo "$USER_RESPONSE" | jq .
USER_ID=$(echo "$USER_RESPONSE" | jq -r '.user_id')

echo -e "\n\nGetting user by ID..."
curl -s "$BASE_URL/api/users/$USER_ID" | jq .

echo -e "\n\nCreating vocabulary card..."
curl -s -X POST "$BASE_URL/api/vocabulary" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"language_code\": \"spanish-es\",
    \"front_text\": \"computer\",
    \"back_text\": \"computadora\",
    \"context\": \"technology\",
    \"dialect\": \"general\"
  }" | jq .

echo -e "\n\nGetting user vocabulary..."
curl -s "$BASE_URL/api/vocabulary/user/$USER_ID" | jq .

echo -e "\n\n✅ All tests complete!"
