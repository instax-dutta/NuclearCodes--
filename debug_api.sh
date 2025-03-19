#!/bin/bash

# This script helps debug the SERP API by testing it directly on the server

echo "SERP API Debugging Tool"
echo "======================="

# Function to test the API with a query
test_query() {
    local query="$1"
    echo "Testing query: '$query'"
    echo "Response from localhost:7777:"
    curl -s "http://localhost:7777/search?query=$query" | python3 -m json.tool
    echo -e "\nResponse from public URL:"
    curl -s "http://serp.sdad.pro/search?query=$query" | python3 -m json.tool
    echo "----------------------------------------"
}

# Check if the service is running
echo "1. Checking if the SERP API service is running:"
sudo systemctl is-active serp-api
echo

# Restart the service to ensure it's fresh
echo "2. Restarting the SERP API service:"
sudo systemctl restart serp-api
sleep 2
echo "Service restarted."
echo

# Test with some common queries
echo "3. Testing API with common queries:"
test_query "python"
test_query "data science"
test_query "machine learning"

# Check the Python dependencies
echo "4. Checking installed Python packages:"
cd /home/ubuntu/serp
source venv/bin/activate
pip list | grep -E 'requests|fastapi|uvicorn|httpx|beautifulsoup4|lxml'
echo

echo "5. Checking API configuration:"
grep -v '^#' /home/ubuntu/serp/.env
echo

echo "Debugging completed. If you're still seeing issues, please check the logs with ./check_logs.sh"