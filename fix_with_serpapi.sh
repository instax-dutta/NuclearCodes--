#!/bin/bash

# This script updates the SERP API to use SerpAPI instead of direct scraping

echo "SERP API Update Tool (Using SerpAPI)"
echo "==================================="

# Check if we're in the right directory
if [ "$(pwd)" != "/home/ubuntu/serp" ]; then
    echo "This script should be run from the /home/ubuntu/serp directory."
    echo "Current directory: $(pwd)"
    echo "Please change to the correct directory and try again."
    exit 1
fi

# Backup current files
echo "1. Creating backup of current serp_api.py..."
mkdir -p backups
cp serp_api.py backups/serp_api.py.bak.$(date +%Y%m%d%H%M%S)
echo "Backup created."
echo

# Update dependencies
echo "2. Installing SerpAPI client..."
source venv/bin/activate
pip install --upgrade pip
pip install --upgrade google-search-results
echo "SerpAPI client installed."
echo

# Ask for SerpAPI key
echo "3. SerpAPI requires an API key."
echo "   You can get a free API key at https://serpapi.com/users/sign_up"
echo "   Please enter your SerpAPI key (or press Enter to skip):"
read serpapi_key

if [ -z "$serpapi_key" ]; then
    echo "No SerpAPI key provided. Using demo mode with limited functionality."
    serpapi_key="demo"
fi

# Update .env file with SerpAPI key
echo "4. Updating .env file with SerpAPI key..."
if [ -f .env ]; then
    # Check if SERPAPI_KEY already exists in .env
    if grep -q "SERPAPI_KEY" .env; then
        # Update existing SERPAPI_KEY
        sed -i "s/SERPAPI_KEY=.*/SERPAPI_KEY=$serpapi_key/" .env
    else
        # Add SERPAPI_KEY to .env
        echo "SERPAPI_KEY=$serpapi_key" >> .env
    fi
else
    # Create new .env file
    echo "PORT=7777" > .env
    echo "SERPAPI_KEY=$serpapi_key" >> .env
fi
echo ".env file updated."
echo

# Update the serp_api.py file to use SerpAPI
echo "5. Updating serp_api.py to use SerpAPI..."
cat > serp_api.py << 'EOL'
#!/usr/bin/env python3
"""
SERP API - A simple API for searching Google and returning structured results
Using SerpAPI as the backend
"""

import os
import json
import logging
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from dotenv import load_dotenv
from serpapi import GoogleSearch

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("serp_api.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("serp_api")

# Load environment variables
load_dotenv()
PORT = int(os.getenv("PORT", 7777))
SERPAPI_KEY = os.getenv("SERPAPI_KEY", "demo")

# Initialize FastAPI
app = FastAPI(
    title="SERP API",
    description="API for searching Google and returning structured results",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define request and response models
class SearchRequest(BaseModel):
    query: str
    num_results: int = 10
    language: str = "en"
    country: str = "us"

class SearchResult(BaseModel):
    title: str
    url: str
    description: str
    position: int
    additional_links: Optional[List[Dict[str, str]]] = None

class SearchResponse(BaseModel):
    query: str
    results_count: int
    organic_results: List[SearchResult]
    related_searches: Optional[List[str]] = None

@app.get("/")
async def root():
    """Root endpoint that returns API information"""
    return {
        "name": "SERP API",
        "version": "1.0.0",
        "description": "API for searching Google and returning structured results",
        "endpoints": {
            "/search": "Search Google and return structured results"
        }
    }

@app.get("/search", response_model=Dict[str, Any])
async def search_get(
    query: str = Query(..., description="Search query"),
    num_results: int = Query(10, description="Number of results to return"),
    language: str = Query("en", description="Language code"),
    country: str = Query("us", description="Country code")
):
    """Search Google and return structured results using GET method"""
    logger.info(f"GET Search request received: {query}")
    return perform_search(query, num_results, language, country)

@app.post("/search", response_model=Dict[str, Any])
async def search_post(request: SearchRequest):
    """Search Google and return structured results using POST method"""
    logger.info(f"POST Search request received: {request.query}")
    return perform_search(
        request.query,
        request.num_results,
        request.language,
        request.country
    )

def perform_search(query: str, num_results: int = 10, language: str = "en", country: str = "us") -> Dict[str, Any]:
    """Perform a search using SerpAPI and return structured results"""
    try:
        # Set up SerpAPI parameters
        params = {
            "q": query,
            "num": num_results,
            "hl": language,
            "gl": country,
            "api_key": SERPAPI_KEY
        }
        
        logger.info(f"Searching for: {query}")
        
        # Perform the search
        search = GoogleSearch(params)
        results = search.get_dict()
        
        # Extract organic results
        organic_results = []
        if "organic_results" in results:
            position = 1
            for result in results["organic_results"][:num_results]:
                organic_result = {
                    "title": result.get("title", "No Title"),
                    "url": result.get("link", "No URL"),
                    "description": result.get("snippet", "No description available"),
                    "position": position
                }
                
                # Add additional links if available
                if "sitelinks" in result:
                    additional_links = []
                    for sitelink in result["sitelinks"]:
                        additional_links.append({
                            "title": sitelink.get("title", ""),
                            "url": sitelink.get("link", "")
                        })
                    organic_result["additional_links"] = additional_links
                
                organic_results.append(organic_result)
                position += 1
        
        # Extract related searches
        related_searches = []
        if "related_searches" in results:
            for related in results["related_searches"]:
                related_searches.append(related.get("query", ""))
        
        # Prepare response
        response_data = {
            "query": query,
            "results_count": len(organic_results),
            "organic_results": organic_results
        }
        
        if related_searches:
            response_data["related_searches"] = related_searches
        
        return response_data
        
    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error occurred: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("serp_api:app", host="0.0.0.0", port=PORT, reload=True)
EOL
echo "serp_api.py updated to use SerpAPI."
echo

# Update requirements.txt
echo "6. Updating requirements.txt..."
cat > requirements.txt << 'EOL'
fastapi>=0.68.0
uvicorn>=0.15.0
httpx>=0.19.0
beautifulsoup4>=4.10.0
lxml>=4.6.3
python-dotenv>=0.19.0
google-search-results>=2.4.1
EOL
echo "requirements.txt updated."
echo

# Install dependencies
echo "7. Installing dependencies..."
pip install -r requirements.txt
echo "Dependencies installed."
echo

# Restart the service
echo "8. Restarting the SERP API service..."
sudo systemctl restart serp-api
echo "Service restarted."
echo

# Wait for the service to start
echo "9. Waiting for the service to start..."
sleep 3
echo "Service should be up now."
echo

# Test the API
echo "10. Testing the API..."
curl -s "http://localhost:7777/search?query=python+programming" | python3 -m json.tool
echo

echo "Update completed. The SERP API now uses SerpAPI as the backend."
echo "Please test the API again with your client to see if it's now returning results."
echo ""
echo "Note: SerpAPI offers a free tier with 100 searches per month."
echo "If you need more searches, you can upgrade to a paid plan at https://serpapi.com/pricing"
echo ""
echo "If you're still experiencing issues, please check the logs with ./check_logs.sh"