#!/usr/bin/env python3
"""
Simple test client for the SERP API
"""

import requests
import json
import sys

def test_api(query, api_url="http://localhost:7777"):
    """Test the SERP API with a query"""
    print(f"Testing query: {query}")
    url = f"{api_url}/search"
    params = {"query": query, "num_results": 5}
    
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json()
        
        print(f"Status: {response.status_code}")
        print(f"Results count: {data.get('results_count', 0)}")
        
        if data.get('results_count', 0) > 0:
            print("\nResults:")
            for i, result in enumerate(data.get('organic_results', []), 1):
                print(f"{i}. {result.get('title', 'No title')}")
                print(f"   URL: {result.get('url', 'No URL')}")
                print(f"   {result.get('description', 'No description')[:100]}...")
                print()
        else:
            print("\nNo results found. This is expected due to the limitations of this project.")
            print("See the README.md and docs/limitations.md for more information.")
        
    except requests.exceptions.RequestException as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    query = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "python programming"
    test_api(query)
