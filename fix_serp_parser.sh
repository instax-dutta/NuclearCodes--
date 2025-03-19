#!/bin/bash

# This script fixes the SERP API parser issues

echo "SERP API Parser Fix Tool"
echo "======================="

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

# Update the serp_api.py file with improved parser
echo "2. Updating serp_api.py with improved parser..."
cat > serp_api.py << 'EOL'
#!/usr/bin/env python3
"""
SERP API - A simple API for searching Google and returning structured results
"""

import os
import json
import logging
import httpx
from bs4 import BeautifulSoup
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from dotenv import load_dotenv

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
    return await perform_search(query, num_results, language, country)

@app.post("/search", response_model=Dict[str, Any])
async def search_post(request: SearchRequest):
    """Search Google and return structured results using POST method"""
    logger.info(f"POST Search request received: {request.query}")
    return await perform_search(
        request.query,
        request.num_results,
        request.language,
        request.country
    )

async def perform_search(query: str, num_results: int = 10, language: str = "en", country: str = "us") -> Dict[str, Any]:
    """Perform a search and return structured results"""
    try:
        # Construct the Google search URL
        url = f"https://www.google.com/search?q={query.replace(' ', '+')}&num={num_results}&hl={language}&gl={country}"
        
        # Set up headers to mimic a browser
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Referer": "https://www.google.com/",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1"
        }
        
        # Make the request
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, follow_redirects=True)
            response.raise_for_status()
            logger.info(f"HTTP Request: GET {url} \"{response.status_code} {response.reason_phrase}\"")
            
            # Parse the HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extract organic results
            organic_results = []
            result_divs = soup.select("div.g")
            
            # If no results found with div.g, try alternative selectors
            if not result_divs:
                result_divs = soup.select("div.tF2Cxc")
            
            # If still no results, try another selector pattern
            if not result_divs:
                result_divs = soup.select("div[data-hveid]")
            
            position = 1
            for div in result_divs:
                # Try to extract title
                title_elem = div.select_one("h3")
                if not title_elem:
                    continue
                title = title_elem.get_text()
                
                # Try to extract URL
                url_elem = div.select_one("a")
                if not url_elem or not url_elem.has_attr("href"):
                    continue
                url = url_elem["href"]
                if url.startswith("/url?q="):
                    url = url.split("/url?q=")[1].split("&")[0]
                elif not url.startswith("http"):
                    continue
                
                # Try to extract description
                desc_elem = div.select_one("div.VwiC3b") or div.select_one("span.aCOpRe") or div.select_one("div.IsZvec")
                description = desc_elem.get_text() if desc_elem else "No description available"
                
                # Additional links (if any)
                additional_links = []
                link_elems = div.select("a.fl")
                for link in link_elems:
                    if link.has_attr("href") and link.get_text():
                        additional_links.append({
                            "title": link.get_text(),
                            "url": link["href"] if link["href"].startswith("http") else f"https://www.google.com{link['href']}"
                        })
                
                result = {
                    "title": title,
                    "url": url,
                    "description": description,
                    "position": position
                }
                
                if additional_links:
                    result["additional_links"] = additional_links
                
                organic_results.append(result)
                position += 1
                
                # Limit to requested number of results
                if len(organic_results) >= num_results:
                    break
            
            # Extract related searches
            related_searches = []
            related_elems = soup.select("div.AJLUJb > div > a") or soup.select("div.s75CSd > a")
            for elem in related_elems:
                related_searches.append(elem.get_text())
            
            # Prepare response
            response_data = {
                "query": query,
                "results_count": len(organic_results),
                "organic_results": organic_results
            }
            
            if related_searches:
                response_data["related_searches"] = related_searches
            
            return response_data
            
    except httpx.HTTPError as e:
        logger.error(f"HTTP error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=f"HTTP error occurred: {str(e)}")
    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error occurred: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("serp_api:app", host="0.0.0.0", port=PORT, reload=True)
EOL
echo "serp_api.py updated with improved parser."
echo

# Update dependencies
echo "3. Updating Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install --upgrade requests beautifulsoup4 lxml httpx fastapi uvicorn python-dotenv
echo "Dependencies updated."
echo

# Restart the service
echo "4. Restarting the SERP API service..."
sudo systemctl restart serp-api
echo "Service restarted."
echo

# Wait for the service to start
echo "5. Waiting for the service to start..."
sleep 3
echo "Service should be up now."
echo

# Test the API
echo "6. Testing the API..."
curl -s "http://localhost:7777/search?query=python+programming" | python3 -m json.tool
echo

echo "Fix completed. The SERP API parser has been updated to better handle Google's HTML structure."
echo "Please test the API again with your client to see if it's now returning results."
echo "If you're still experiencing issues, please check the logs with ./check_logs.sh"