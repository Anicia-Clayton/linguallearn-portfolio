#!/bin/bash
# Comprehensive API Testing Script with Error Handling

# ============================================================================
# ANSI COLOR CODES
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# CONFIGURATION
# ============================================================================


# Tests the full stack: DNS → SSL → ALB → EC2
BASE_URL="https://api.linguallearn.org"

# Use ALB DNS directly for initial testing or debugging
# BASE_URL="http://<YOUR_ALB_DNS_NAME>"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

print_header "PRE-FLIGHT CHECKS"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is not installed. Installing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed. Installing..."
    sudo apt-get update && sudo apt-get install -y curl
fi

print_success "All dependencies installed"

# Validate BASE_URL is configured
if [[ "$BASE_URL" == *"<"*">"* ]] || [[ -z "$BASE_URL" ]]; then
    print_error "BASE_URL is not configured!"
    echo ""
    echo "Set BASE_URL to custom domain for use"
    echo "  BASE_URL=\"https://api.linguallearn.org\""
    echo ""
    echo "Set BASE_URL to ALB DNS for debugging"
    echo "  BASE_URL=\"http://linguallearn-alb-dev-91547010.us-east-1.elb.amazonaws.com\""
    echo ""
    exit 1
fi

print_info "Testing against: $BASE_URL"

# Test connectivity to BASE_URL
echo ""
print_info "Testing connectivity to $BASE_URL..."
if curl -s -f -o /dev/null --max-time 5 "$BASE_URL/api/health" 2>/dev/null; then
    print_success "Successfully connected to $BASE_URL"
else
    print_error "Cannot reach $BASE_URL"
    echo ""
    echo "Troubleshooting:"
    echo "  • If using custom domain, verify DNS propagation: nslookup api.linguallearn.org"
    echo "  • If using ALB DNS, check ALB is running: aws elbv2 describe-load-balancers"
    echo "  • Check security groups allow HTTP/HTTPS traffic"
    echo "  • Try the other BASE_URL option to isolate the issue"
    echo ""
    print_info "Continuing with tests anyway (may fail)..."
fi

# ============================================================================
# TEST 1: HEALTH CHECK
# ============================================================================

print_header "TEST 1: Health Check Endpoint"

HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/health")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

echo "Response Body:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

if [ "$HTTP_CODE" -eq 200 ]; then
    print_success "Health check passed (HTTP $HTTP_CODE)"
else
    print_error "Health check failed (HTTP $HTTP_CODE)"
    echo ""
    print_info "Troubleshooting steps:"
    echo "  1. Check if ALB is accessible: curl $BASE_URL/api/health"
    echo "  2. Verify API is running: sudo systemctl status linguallearn-api"
    echo "  3. Check API logs: sudo journalctl -u linguallearn-api -n 50"
    echo ""
    exit 1
fi

# ============================================================================
# TEST 2: CREATE USER
# ============================================================================

print_header "TEST 2: Create Test User"

USER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@linguallearn.com",
    "username": "demouser",
    "password": "Demo123!",
    "role": "learner"
  }')

HTTP_CODE=$(echo "$USER_RESPONSE" | tail -n1)
BODY=$(echo "$USER_RESPONSE" | sed '$d')

echo "Response Body:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ]; then
    USER_ID=$(echo "$BODY" | jq -r '.user_id // .id')
    print_success "User created successfully (HTTP $HTTP_CODE)"
    print_info "User ID: $USER_ID"
    elif [ "$HTTP_CODE" -eq 409 ] || [[ "$BODY" == *"duplicate"* ]] || [[ "$BODY" == *"already exists"* ]]; then
    print_info "User already exists (HTTP $HTTP_CODE) - this is okay for testing"
    # Try to extract user_id from error response or use a known test user
    USER_ID=$(echo "$BODY" | jq -r '.user_id // .id' 2>/dev/null)
    if [ "$USER_ID" == "null" ] || [ -z "$USER_ID" ]; then
        # Fallback: try to get the user by querying
        print_info "Attempting to retrieve existing user..."
        # For now, use a placeholder
        USER_ID="1"
    fi
else
    print_error "User creation failed (HTTP $HTTP_CODE)"
    echo ""
    print_info "Troubleshooting steps:"
    echo "  1. Check database connection: psql -U linguallearn_user -d linguallearn_db -c '\\dt'"
    echo "  2. Verify API logs: sudo journalctl -u linguallearn-api -n 50"
    echo "  3. Test database manually: psql -U linguallearn_user -d linguallearn_db"
    echo ""
    # Continue with remaining tests using a fallback user_id
    USER_ID="2"
    print_info "Continuing tests with fallback user_id..."
fi

# ============================================================================
# TEST 3: GET USER BY ID
# ============================================================================

print_header "TEST 3: Get User by ID"

if [ "$USER_ID" != "null" ] && [ -n "$USER_ID" ]; then
    GET_USER_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/users/$USER_ID")
    HTTP_CODE=$(echo "$GET_USER_RESPONSE" | tail -n1)
    BODY=$(echo "$GET_USER_RESPONSE" | sed '$d')

    echo "Response Body:"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

    if [ "$HTTP_CODE" -eq 200 ]; then
        print_success "Get user successful (HTTP $HTTP_CODE)"
    else
        print_error "Get user failed (HTTP $HTTP_CODE)"
        echo ""
        print_info "This might be expected if user creation failed earlier"
    fi
    else
    print_error "Skipping - no valid USER_ID from previous test"
fi

# ============================================================================
# TEST 4: CREATE VOCABULARY CARD
# ============================================================================

print_header "TEST 4: Create Vocabulary Card"

if [ "$USER_ID" != "null" ] && [ -n "$USER_ID" ]; then
    VOCAB_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/vocabulary" \
      -H "Content-Type: application/json" \
      -d "{
        \"user_id\": \"$USER_ID\",
        \"language_code\": \"spanish-es\",
        \"word_native\": \"computer\",
        \"word_target\": \"computadora\",
        \"context_sentence\": \"technology\"
        }")

    HTTP_CODE=$(echo "$VOCAB_RESPONSE" | tail -n1)
    BODY=$(echo "$VOCAB_RESPONSE" | sed '$d')

    echo "Response Body:"
     echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ]; then
        VOCAB_ID=$(echo "$BODY" | jq -r '.vocab_id // .id')
        print_success "Vocabulary card created (HTTP $HTTP_CODE)"
        print_info "Vocabulary ID: $VOCAB_ID"
    else
        print_error "Vocabulary creation failed (HTTP $HTTP_CODE)"
        echo ""
        print_info "Troubleshooting steps:"
        echo "  1. Verify vocabulary table exists: psql -U linguallearn_user -d linguallearn_db -c '\\dt'"
        echo "  2. Check API logs: sudo journalctl -u linguallearn-api -n 50"
        echo ""
    fi
else
    print_error "Skipping - no valid USER_ID"
fi

# ============================================================================
# TEST 5: GET USER VOCABULARY
# ============================================================================

print_header "TEST 5: Get User's Vocabulary"

if [ "$USER_ID" != "null" ] && [ -n "$USER_ID" ]; then
 GET_VOCAB_RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/vocabulary/user/$USER_ID")
    HTTP_CODE=$(echo "$GET_VOCAB_RESPONSE" | tail -n1)
    BODY=$(echo "$GET_VOCAB_RESPONSE" | sed '$d')

    echo "Response Body:"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"

    if [ "$HTTP_CODE" -eq 200 ]; then
        VOCAB_COUNT=$(echo "$BODY" | jq 'length' 2>/dev/null || echo "0")
        print_success "Retrieved vocabulary (HTTP $HTTP_CODE)"
        print_info "Vocabulary count: $VOCAB_COUNT"
    else
        print_error "Get vocabulary failed (HTTP $HTTP_CODE)"
    fi
else
    print_error "Skipping - no valid USER_ID"
fi

# ============================================================================
# SUMMARY
# ============================================================================

print_header "TEST SUMMARY"

echo -e "${GREEN}✅ All API tests completed!${NC}\n"

print_info "Next Steps:"
echo "  1. Review any failed tests above"
echo "  2. Check API logs if needed: sudo journalctl -u linguallearn-api -f"
echo "  3. Verify database records: psql -U linguallearn_user -d linguallearn_db -c 'SELECT * FROM users LIMIT 5;'"
echo "  4. Test manually in browser: $BASE_URL/api/health"
echo ""
print_success "Comprehensive API Testing: COMPLETE!"
echo ""
