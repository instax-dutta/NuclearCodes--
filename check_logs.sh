#!/bin/bash

# This script helps check logs on the server to diagnose API issues

echo "Checking SERP API logs and status..."
echo "===================================="

# Check if the service is running
echo "1. Checking if the SERP API service is running:"
sudo systemctl status serp-api | head -n 20

# Check the API logs
echo -e "\n2. Checking the last 20 lines of the API log file:"
tail -n 20 /home/ubuntu/serp/serp_api.log

# Check Nginx logs
echo -e "\n3. Checking Nginx access logs (last 10 lines):"
sudo tail -n 10 /var/log/nginx/access.log

echo -e "\n4. Checking Nginx error logs (last 10 lines):"
sudo tail -n 10 /var/log/nginx/error.log

# Check if the API endpoint is accessible locally
echo -e "\n5. Testing API locally on the server:"
curl -s "http://localhost:7777/search?query=test" | head -c 300
echo -e "\n..."

# Check if the port is open and listening
echo -e "\n6. Checking if port 7777 is listening:"
sudo lsof -i :7777

echo -e "\n7. Checking environment variables:"
grep -v '^#' /home/ubuntu/serp/.env

echo -e "\nTroubleshooting completed. Please review the output above for any errors."