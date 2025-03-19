#!/bin/bash

# Exit on error
set -e

echo "Setting up SERP API (ARCHIVED PROJECT)"
echo "====================================="
echo "NOTE: This project has known limitations with Google scraping."
echo "It is provided for educational purposes only."
echo

# Create and activate virtual environment
echo "1. Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "2. Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Run the API locally for testing
echo "3. Running the API locally for testing..."
echo "Press Ctrl+C to stop the API when done testing."
python -m uvicorn src.serp_api:app --host 0.0.0.0 --port 7777
