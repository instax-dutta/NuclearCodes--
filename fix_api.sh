#!/bin/bash

# This script attempts to fix common issues with the SERP API

echo "SERP API Fix Tool"
echo "================="

# Check if we're in the right directory
if [ "$(pwd)" != "/home/ubuntu/serp" ]; then
    echo "This script should be run from the /home/ubuntu/serp directory."
    echo "Current directory: $(pwd)"
    echo "Please change to the correct directory and try again."
    exit 1
fi

# Backup current files
echo "1. Creating backups of current files..."
mkdir -p backups
cp serp_api.py backups/serp_api.py.bak
cp .env backups/.env.bak
cp requirements.txt backups/requirements.txt.bak
echo "Backups created in the 'backups' directory."
echo

# Update dependencies
echo "2. Updating Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install --upgrade requests beautifulsoup4 lxml httpx fastapi uvicorn python-dotenv
pip install --upgrade google-search-results
echo "Dependencies updated."
echo

# Check if the .env file exists and has the necessary variables
echo "3. Checking and updating environment variables..."
if [ ! -f .env ]; then
    echo "Creating .env file..."
    echo "PORT=7777" > .env
    echo "SERPAPI_KEY=your_serpapi_key_here" >> .env
    echo "Please update the SERPAPI_KEY in the .env file with your actual API key."
else
    # Check if SERPAPI_KEY exists in .env
    if ! grep -q "SERPAPI_KEY" .env; then
        echo "Adding SERPAPI_KEY to .env file..."
        echo "SERPAPI_KEY=your_serpapi_key_here" >> .env
        echo "Please update the SERPAPI_KEY in the .env file with your actual API key."
    fi
    
    # Ensure PORT is set to 7777
    if grep -q "PORT=" .env; then
        sed -i 's/PORT=.*/PORT=7777/' .env
    else
        echo "PORT=7777" >> .env
    fi
fi
echo "Environment variables updated."
echo

# Restart the service
echo "4. Restarting the SERP API service..."
sudo systemctl restart serp-api
echo "Service restarted."
echo

# Test the API
echo "5. Testing the API..."
sleep 2
curl -s "http://localhost:7777/search?query=test" | python3 -m json.tool
echo

echo "Fix completed. Please check if the API is now returning results."
echo "If you're still experiencing issues, you may need to check the logs with ./check_logs.sh"
echo "or debug the API with ./debug_api.sh"