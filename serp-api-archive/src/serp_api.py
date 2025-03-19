from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import os
from typing import Optional, List, Dict, Any
import json
from bs4 import BeautifulSoup
import re
from dotenv import load_dotenv
import logging
from fastapi.responses import JSONResponse

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/home/ubuntu/serp/serp_api.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("serp_api")

app = FastAPI(title="SERP API", description="Free API for search engine results", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for free API
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SearchRequest(BaseModel):
    query: str
    num_results: Optional[int] = 10
    language: Optional[str] = "en"
    country: Optional[str] = "us"

async def google_search(query: str, num_results: int = 10, language: str = "en", country: str = "us") -> Dict[str, Any]:
    """
    Perform a Google search and extract results
    """
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }
        
        params = {
            "q": query,
            "num": num_results,
            "hl": language,
            "gl": country,
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get("https://www.google.com/search", params=params, headers=headers)
            
        if response.status_code != 200:
            logger.error(f"Google search failed with status code: {response.status_code}")
            return {"error": f"Search failed with status code: {response.status_code}"}
            
        # Parse the HTML response
        soup = BeautifulSoup(response.text, "html.parser")
        
        # Extract organic search results
        search_results = []
        result_blocks = soup.select("div.g")
        
        for block in result_blocks:
            try:
                # Extract title
                title_element = block.select_one("h3")
                title = title_element.text if title_element else "No title found"
                
                # Extract URL
                link_element = block.select_one("a")
                link = link_element["href"] if link_element and "href" in link_element.attrs else None
                
                # Clean URL (remove Google redirects)
                if link and link.startswith("/url?q="):
                    link = link.split("/url?q=")[1].split("&sa=")[0]
                
                # Extract snippet
                snippet_element = block.select_one("div.VwiC3b")
                snippet = snippet_element.text if snippet_element else "No snippet found"
                
                if link:  # Only add results with valid links
                    search_results.append({
                        "title": title,
                        "link": link,
                        "snippet": snippet
                    })
            except Exception as e:
                logger.error(f"Error parsing search result: {str(e)}")
                continue
                
        return {
            "query": query,
            "results_count": len(search_results),
            "results": search_results[:num_results]
        }
        
    except Exception as e:
        logger.error(f"Error in Google search: {str(e)}")
        return {"error": str(e)}

@app.get("/")
async def root():
    return {"message": "Welcome to the free SERP API. Use /search endpoint to get search results."}

@app.post("/search")
async def search(request: SearchRequest):
    """
    Search endpoint that returns search engine results
    """
    try:
        logger.info(f"Search request received: {request.query}")
        results = await google_search(
            query=request.query,
            num_results=request.num_results,
            language=request.language,
            country=request.country
        )
        return results
    except Exception as e:
        logger.error(f"Error processing search request: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"error": f"Failed to process search request: {str(e)}"}
        )

@app.get("/search")
async def search_get(
    query: str = Query(..., description="Search query"),
    num_results: int = Query(10, description="Number of results to return"),
    language: str = Query("en", description="Language code"),
    country: str = Query("us", description="Country code")
):
    """
    GET endpoint for search that returns search engine results
    """
    try:
        logger.info(f"GET Search request received: {query}")
        results = await google_search(
            query=query,
            num_results=num_results,
            language=language,
            country=country
        )
        return results
    except Exception as e:
        logger.error(f"Error processing GET search request: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"error": f"Failed to process search request: {str(e)}"}
        )

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 7777))
    uvicorn.run("serp_api:app", host="0.0.0.0", port=port, reload=True)