#!/usr/bin/env python3
"""
SERP API Test Client

This script allows you to test your SERP API by sending search queries
and displaying the results in a readable format.

Usage:
    python test_serp_api.py

The script will prompt you for:
1. The API URL (default: http://serp.sdad.pro)
2. A search query
3. Number of results to return (default: 10)

Requirements:
    - Python 3.6+
    - requests library (pip install requests)
    - colorama library (pip install colorama) - for colored output
"""

import requests
import json
import sys
import argparse
from datetime import datetime
try:
    from colorama import init, Fore, Style
    # Initialize colorama
    init()
    COLORAMA_AVAILABLE = True
except ImportError:
    COLORAMA_AVAILABLE = False

def print_colored(text, color=None, style=None):
    """Print colored text if colorama is available."""
    if COLORAMA_AVAILABLE:
        color_code = getattr(Fore, color.upper()) if color else ''
        style_code = getattr(Style, style.upper()) if style else ''
        print(f"{color_code}{style_code}{text}{Style.RESET_ALL}")
    else:
        print(text)

def print_header(text):
    """Print a header with decoration."""
    width = len(text) + 4
    if COLORAMA_AVAILABLE:
        print(f"{Fore.CYAN}{Style.BRIGHT}{'=' * width}{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{Style.BRIGHT}= {text} ={Style.RESET_ALL}")
        print(f"{Fore.CYAN}{Style.BRIGHT}{'=' * width}{Style.RESET_ALL}")
    else:
        print('=' * width)
        print(f"= {text} =")
        print('=' * width)

def print_result(index, result):
    """Print a search result in a formatted way."""
    if COLORAMA_AVAILABLE:
        print(f"{Fore.GREEN}{Style.BRIGHT}[{index}] {result.get('title', 'No Title')}{Style.RESET_ALL}")
        print(f"{Fore.BLUE}{result.get('url', 'No URL')}{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}{result.get('description', 'No description available')}{Style.RESET_ALL}")
    else:
        print(f"[{index}] {result.get('title', 'No Title')}")
        print(f"{result.get('url', 'No URL')}")
        print(f"{result.get('description', 'No description available')}")
    print()

def test_api_get(api_url, query, num_results=10):
    """Test the API using GET request."""
    url = f"{api_url}/search"
    params = {
        "query": query,
        "num_results": num_results
    }
    
    print_colored(f"Sending GET request to {url}", "yellow")
    print_colored(f"Parameters: {params}", "yellow")
    print()
    
    try:
        start_time = datetime.now()
        response = requests.get(url, params=params, timeout=30)
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        if response.status_code == 200:
            data = response.json()
            return data, duration
        else:
            print_colored(f"Error: Received status code {response.status_code}", "red", "bright")
            print_colored(f"Response: {response.text}", "red")
            return None, duration
    except requests.exceptions.RequestException as e:
        print_colored(f"Request failed: {str(e)}", "red", "bright")
        return None, 0

def test_api_post(api_url, query, num_results=10):
    """Test the API using POST request."""
    url = f"{api_url}/search"
    data = {
        "query": query,
        "num_results": num_results
    }
    
    print_colored(f"Sending POST request to {url}", "yellow")
    print_colored(f"Data: {data}", "yellow")
    print()
    
    try:
        start_time = datetime.now()
        response = requests.post(url, json=data, timeout=30)
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        if response.status_code == 200:
            data = response.json()
            return data, duration
        else:
            print_colored(f"Error: Received status code {response.status_code}", "red", "bright")
            print_colored(f"Response: {response.text}", "red")
            return None, duration
    except requests.exceptions.RequestException as e:
        print_colored(f"Request failed: {str(e)}", "red", "bright")
        return None, 0

def display_results(data, duration):
    """Display the search results in a readable format."""
    if not data:
        return
    
    # Extract results
    organic_results = data.get("organic_results", [])
    related_searches = data.get("related_searches", [])
    
    # Print organic results
    print_header("Search Results")
    if organic_results:
        for i, result in enumerate(organic_results, 1):
            print_result(i, result)
    else:
        print_colored("No organic results found.", "red")
    
    # Print related searches if available
    if related_searches:
        print_header("Related Searches")
        for i, search in enumerate(related_searches, 1):
            print_colored(f"[{i}] {search}", "magenta")
    
    # Print statistics
    print_header("Statistics")
    print_colored(f"Total results: {len(organic_results)}", "cyan")
    print_colored(f"Response time: {duration:.2f} seconds", "cyan")

def main():
    parser = argparse.ArgumentParser(description="Test the SERP API")
    parser.add_argument("--url", default="http://serp.sdad.pro", help="API URL (default: http://serp.sdad.pro)")
    parser.add_argument("--query", help="Search query")
    parser.add_argument("--results", type=int, default=10, help="Number of results to return (default: 10)")
    parser.add_argument("--method", choices=["get", "post"], default="get", help="HTTP method to use (default: get)")
    
    args = parser.parse_args()
    
    # Get API URL
    api_url = args.url
    if not api_url:
        api_url = input("Enter API URL (default: http://serp.sdad.pro): ").strip() or "http://serp.sdad.pro"
    
    # Get search query
    query = args.query
    if not query:
        query = input("Enter search query: ").strip()
        if not query:
            print_colored("Error: Search query cannot be empty", "red", "bright")
            sys.exit(1)
    
    # Get number of results
    num_results = args.results
    if args.results <= 0:
        num_results_input = input("Enter number of results (default: 10): ").strip()
        num_results = int(num_results_input) if num_results_input else 10
    
    # Choose method
    method = args.method
    if not args.method:
        method_input = input("Choose HTTP method (get/post, default: get): ").strip().lower()
        method = method_input if method_input in ["get", "post"] else "get"
    
    print_header("SERP API Test")
    print_colored(f"API URL: {api_url}", "cyan")
    print_colored(f"Query: {query}", "cyan")
    print_colored(f"Number of results: {num_results}", "cyan")
    print_colored(f"HTTP Method: {method.upper()}", "cyan")
    print()
    
    # Test the API
    if method == "get":
        data, duration = test_api_get(api_url, query, num_results)
    else:
        data, duration = test_api_post(api_url, query, num_results)
    
    # Display results
    if data:
        display_results(data, duration)
    
if __name__ == "__main__":
    main()