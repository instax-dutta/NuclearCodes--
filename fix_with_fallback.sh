#!/bin/bash

# This script updates the SERP API with a more robust parser and fallback mechanisms

echo "SERP API Robust Parser Update"
echo "============================"

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
echo "2. Updating Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install --upgrade requests beautifulsoup4 lxml httpx fastapi uvicorn python-dotenv
pip install --upgrade google-search-results
pip install --upgrade fake-useragent
echo "Dependencies updated."
echo

# Update the serp_api.py file with a more robust parser
echo "3. Updating serp_api.py with a more robust parser..."
cat > serp_api.py << 'EOL'
#!/usr/bin/env python3
"""
SERP API - A simple API for searching Google and returning structured results
With multiple fallback mechanisms
"""

import os
import json
import logging
import random
import time
import httpx
from bs4 import BeautifulSoup
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from dotenv import load_dotenv
try:
    from fake_useragent import UserAgent
    ua = UserAgent()
    FAKE_UA_AVAILABLE = True
except:
    FAKE_UA_AVAILABLE = False

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

def get_random_user_agent():
    """Get a random user agent string"""
    if FAKE_UA_AVAILABLE:
        return ua.random
    
    # Fallback user agents if fake_useragent is not available
    user_agents = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36",
    ]
    return random.choice(user_agents)

async def perform_search(query: str, num_results: int = 10, language: str = "en", country: str = "us") -> Dict[str, Any]:
    """Perform a search and return structured results with multiple fallback mechanisms"""
    try:
        # Try different search engines and parsers
        for attempt in range(3):
            try:
                if attempt == 0:
                    # First attempt: Try Google with standard parser
                    logger.info(f"Attempt {attempt+1}: Using Google with standard parser")
                    return await search_google_standard(query, num_results, language, country)
                elif attempt == 1:
                    # Second attempt: Try Google with alternative parser
                    logger.info(f"Attempt {attempt+1}: Using Google with alternative parser")
                    return await search_google_alternative(query, num_results, language, country)
                else:
                    # Third attempt: Try Bing as fallback
                    logger.info(f"Attempt {attempt+1}: Using Bing as fallback")
                    return await search_bing(query, num_results, language, country)
            except Exception as e:
                logger.error(f"Attempt {attempt+1} failed: {str(e)}")
                # Wait before trying the next method
                await asyncio.sleep(1)
        
        # If all attempts fail, return empty results
        logger.error("All search attempts failed")
        return {
            "query": query,
            "results_count": 0,
            "organic_results": []
        }
            
    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error occurred: {str(e)}")

async def search_google_standard(query: str, num_results: int = 10, language: str = "en", country: str = "us") -> Dict[str, Any]:
    """Search Google using the standard parser"""
    # Construct the Google search URL
    url = f"https://www.google.com/search?q={query.replace(' ', '+')}&num={num_results}&hl={language}&gl={country}"
    
    # Set up headers to mimic a browser
    headers = {
        "User-Agent": get_random_user_agent(),
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
        
        # Save the HTML response for debugging (uncomment if needed)
        # with open("google_response.html", "w", encoding="utf-8") as f:
        #     f.write(response.text)
        
        # Parse the HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Extract organic results
        organic_results = []
        
        # Try multiple selector patterns
        result_divs = soup.select("div.g")
        
        # If no results found with div.g, try alternative selectors
        if not result_divs:
            result_divs = soup.select("div.tF2Cxc")
        
        # If still no results, try another selector pattern
        if not result_divs:
            result_divs = soup.select("div[data-hveid]")
            
        # If still no results, try yet another selector pattern
        if not result_divs:
            result_divs = soup.select("div.v7W49e")
            
        # If still no results, try a very generic approach
        if not result_divs:
            result_divs = soup.select("div > a[href^='http']")
        
        position = 1
        for div in result_divs:
            try:
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
            except Exception as e:
                logger.error(f"Error parsing result: {str(e)}")
                continue
        
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

async def search_google_alternative(query: str, num_results: int = 10, language: str = "en", country: str = "us") -> Dict[str, Any]:
    """Search Google using an alternative parser"""
    # Construct the Google search URL with different parameters
    url = f"https://www.google.com/search?q={query.replace(' ', '+')}&num={num_results*2}&hl={language}&gl={country}&pws=0&safe=off"
    
    # Set up headers to mimic a different browser
    headers = {
        "User-Agent": get_random_user_agent(),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1",
        "Cache-Control": "max-age=0"
    }
    
    # Make the request
    async with httpx.AsyncClient() as client:
        response = await client.get(url, headers=headers, follow_redirects=True)
        response.raise_for_status()
        logger.info(f"HTTP Request (Alternative): GET {url} \"{response.status_code} {response.reason_phrase}\"")
        
        # Parse the HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Extract organic results using a different approach
        organic_results = []
        
        # Look for any div that contains an h3 and an anchor tag
        h3_elements = soup.select("h3")
        position = 1
        
        for h3 in h3_elements:
            try:
                # Get the title from h3
                title = h3.get_text()
                
                # Find the closest anchor tag
                parent = h3.parent
                while parent and parent.name != "a" and not parent.select_one("a"):
                    parent = parent.parent
                    if parent is None or parent.name == "body":
                        break
                
                if parent is None:
                    continue
                
                # Get the URL
                url_elem = parent if parent.name == "a" else parent.select_one("a")
                if not url_elem or not url_elem.has_attr("href"):
                    continue
                
                url = url_elem["href"]
                if url.startswith("/url?q="):
                    url = url.split("/url?q=")[1].split("&")[0]
                elif not url.startswith("http"):
                    continue
                
                # Try to find a description
                description = "No description available"
                
                # Look for a description in nearby elements
                next_elem = h3.find_next()
                if next_elem and next_elem.name in ["div", "span", "p"]:
                    description = next_elem.get_text()
                
                result = {
                    "title": title,
                    "url": url,
                    "description": description,
                    "position": position
                }
                
                organic_results.append(result)
                position += 1
                
                # Limit to requested number of results
                if len(organic_results) >= num_results:
                    break
            except Exception as e:
                logger.error(f"Error parsing result (alternative): {str(e)}")
                continue
        
        # Prepare response
        response_data = {
            "query": query,
            "results_count": len(organic_results),
            "organic_results": organic_results
        }
        
        return response_data

async def search_bing(query: str, num_results: int = 10, language: str = "en", country: str = "us") -> Dict[str, Any]:
    """Search Bing as a fallback"""
    # Construct the Bing search URL
    url = f"https://www.bing.com/search?q={query.replace(' ', '+')}&count={num_results}&setlang={language}"
    
    # Set up headers to mimic a browser
    headers = {
        "User-Agent": get_random_user_agent(),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1"
    }
    
    # Make the request
    async with httpx.AsyncClient() as client:
        response = await client.get(url, headers=headers, follow_redirects=True)
        response.raise_for_status()
        logger.info(f"HTTP Request (Bing): GET {url} \"{response.status_code} {response.reason_phrase}\"")
        
        # Parse the HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Extract organic results
        organic_results = []
        result_divs = soup.select("li.b_algo")
        
        position = 1
        for div in result_divs:
            try:
                # Extract title and URL
                h2 = div.select_one("h2")
                if not h2:
                    continue
                
                a = h2.select_one("a")
                if not a or not a.has_attr("href"):
                    continue
                
                title = a.get_text()
                url = a["href"]
                
                # Extract description
                p = div.select_one("p")
                description = p.get_text() if p else "No description available"
                
                result = {
                    "title": title,
                    "url": url,
                    "description": description,
                    "position": position
                }
                
                organic_results.append(result)
                position += 1
                
                # Limit to requested number of results
                if len(organic_results) >= num_results:
                    break
            except Exception as e:
                logger.error(f"Error parsing Bing result: {str(e)}")
                continue
        
        # Prepare response
        response_data = {
            "query": query,
            "results_count": len(organic_results),
            "organic_results": organic_results
        }
        
        return response_data

if __name__ == "__main__":
    import asyncio
    import uvicorn
    uvicorn.run("serp_api:app", host="0.0.0.0", port=PORT, reload=True)
EOL
echo "serp_api.py updated with a more robust parser."
echo

# Update requirements.txt
echo "4. Updating requirements.txt..."
cat > requirements.txt << 'EOL'
fastapi>=0.68.0
uvicorn>=0.15.0
httpx>=0.19.0
beautifulsoup4>=4.10.0
lxml>=4.6.3
python-dotenv>=0.19.0
google-search-results>=2.4.1
fake-useragent>=0.1.11
EOL
echo "requirements.txt updated."
echo

# Install dependencies
echo "5. Installing dependencies..."
pip install -r requirements.txt
echo "Dependencies installed."
echo

# Restart the service
echo "6. Restarting the SERP API service..."
sudo systemctl restart serp-api
echo "Service restarted."
echo

# Wait for the service to start
echo "7. Waiting for the service to start..."
sleep 3
echo "Service should be up now."
echo

# Test the API
echo "8. Testing the API..."
curl -s "http://localhost:7777/search?query=python+programming" | python3 -m json.tool
echo

echo "Update completed. The SERP API now has a more robust parser with fallback mechanisms."
echo "Please test the API again with your client to see if it's now returning results."
echo ""
echo "If you're still experiencing issues, please try the SerpAPI solution with ./fix_with_serpapi.sh"
echo "which uses a paid service (with a free tier) for more reliable results."