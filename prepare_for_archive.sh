#!/bin/bash

# This script prepares the SERP API codebase for public archiving on GitHub

echo "Preparing SERP API codebase for public archiving"
echo "==============================================="

# Create a clean directory structure
echo "1. Creating clean directory structure..."
mkdir -p serp-api-archive/{src,docs,scripts}

# Copy the core files
echo "2. Copying core files..."
cp serp_api.py serp-api-archive/src/
cp requirements.txt serp-api-archive/

# Create a simplified version of the service file
echo "3. Creating simplified service file..."
cat > serp-api-archive/scripts/serp-api.service << 'EOL'
[Unit]
Description=SERP API Service
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/serp
ExecStart=/home/ubuntu/serp/venv/bin/uvicorn serp_api:app --host 0.0.0.0 --port 7777
Restart=always
RestartSec=5
Environment=PYTHONPATH=/home/ubuntu/serp
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

# Create a simplified nginx config
echo "4. Creating simplified nginx config..."
cat > serp-api-archive/scripts/nginx-config << 'EOL'
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:7777;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

# Create a simple setup script
echo "5. Creating simplified setup script..."
cat > serp-api-archive/scripts/setup.sh << 'EOL'
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
EOL

# Make the setup script executable
chmod +x serp-api-archive/scripts/setup.sh

# Create a comprehensive README.md
echo "6. Creating comprehensive README.md..."
cat > serp-api-archive/README.md << 'EOL'
# SERP API (Archived Project)

**IMPORTANT NOTICE: This project is archived and no longer maintained.**

This repository contains a simple API for searching Google and returning structured results. However, due to Google's anti-scraping measures, this approach is **not reliable for production use**.

## Project Status

⚠️ **DEPRECATED**: This project does not work reliably due to Google's anti-scraping measures.

The main issues encountered:
- Google frequently changes their HTML structure, breaking parsers
- Google actively detects and blocks automated requests
- IP-based rate limiting and CAPTCHA challenges
- Inconsistent results or empty result sets

This repository is maintained for **educational purposes only** to demonstrate:
- FastAPI implementation
- Web scraping challenges
- API design patterns

## Better Alternatives

If you need a reliable search API, consider:
- [SerpAPI](https://serpapi.com/) - Reliable Google search API (paid, with free tier)
- [Google Custom Search API](https://developers.google.com/custom-search) - Official Google API (limited free tier)
- [Bing Web Search API](https://www.microsoft.com/en-us/bing/apis/bing-web-search-api) - Microsoft's search API

## Project Structure

```
serp-api/
├── src/                # Source code
│   └── serp_api.py     # Main API implementation
├── scripts/            # Helper scripts
│   ├── setup.sh        # Setup script
│   ├── serp-api.service # Systemd service file
│   └── nginx-config    # Nginx configuration
├── docs/               # Documentation
├── requirements.txt    # Python dependencies
└── README.md           # This file
```

## Installation (For Educational Purposes Only)

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/serp-api.git
   cd serp-api
   ```

2. Run the setup script:
   ```bash
   ./scripts/setup.sh
   ```

3. Test the API:
   ```bash
   curl "http://localhost:7777/search?query=test"
   ```

## API Documentation

### Endpoints

- `GET /`: API information
- `GET /search`: Search with query parameters
- `POST /search`: Search with JSON body

### Example Request

```bash
curl "http://localhost:7777/search?query=python+programming&num_results=5"
```

### Example Response

```json
{
  "query": "python programming",
  "results_count": 5,
  "organic_results": [
    {
      "title": "Python Programming Language",
      "url": "https://www.python.org/",
      "description": "Official Python programming language website",
      "position": 1
    },
    ...
  ]
}
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

This project was created as an educational exercise and is not intended for production use.
EOL

# Create a simple documentation file
echo "7. Creating documentation..."
cat > serp-api-archive/docs/limitations.md << 'EOL'
# SERP API Limitations

This document outlines the limitations of the SERP API project and explains why it was ultimately archived.

## Technical Limitations

### 1. Google's Anti-Scraping Measures

Google has sophisticated mechanisms to detect and block automated scraping:

- **HTML Structure Changes**: Google frequently changes their HTML structure, breaking parsers
- **Bot Detection**: Google uses various signals to detect automated requests
- **IP-based Rate Limiting**: Making too many requests from the same IP can trigger blocks
- **CAPTCHA Challenges**: Suspected bots are served CAPTCHA challenges

### 2. Parser Reliability Issues

The HTML parsing approach used in this project has several reliability issues:

- **Inconsistent Selectors**: CSS selectors that work today may not work tomorrow
- **Empty Results**: Many queries return empty result sets despite successful HTTP responses
- **Parsing Errors**: Changes in HTML structure can cause parsing errors

### 3. Legal and Terms of Service Considerations

Scraping Google search results may violate Google's Terms of Service, which explicitly prohibits:

- Sending automated queries without express permission
- Using software that sends automated queries to Google
- "Scraping" or creating automated methods to access Google services

## Alternatives

For those needing reliable search APIs, consider these alternatives:

### Official APIs

- [Google Custom Search API](https://developers.google.com/custom-search)
- [Bing Web Search API](https://www.microsoft.com/en-us/bing/apis/bing-web-search-api)

### Third-Party Services

- [SerpAPI](https://serpapi.com/)
- [ScrapingBee](https://www.scrapingbee.com/)
- [Proxycrawl](https://proxycrawl.com/)

These services handle the complexities of scraping search engines and provide reliable, structured data.

## Conclusion

This project was an educational exercise to understand API development and the challenges of web scraping. It demonstrates why building reliable scraping tools for major search engines is difficult and why official APIs or specialized third-party services are typically better solutions for production environments.
EOL

# Create a LICENSE file
echo "8. Creating LICENSE file..."
cat > serp-api-archive/LICENSE << 'EOL'
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOL

# Create a .gitignore file
echo "9. Creating .gitignore file..."
cat > serp-api-archive/.gitignore << 'EOL'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Virtual environments
venv/
env/
ENV/

# Environment variables
.env

# Logs
*.log

# IDE files
.idea/
.vscode/
*.swp
*.swo

# OS specific files
.DS_Store
Thumbs.db
EOL

# Create a simple test client
echo "10. Creating a simple test client..."
cat > serp-api-archive/scripts/test_api.py << 'EOL'
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
EOL

# Make the test script executable
chmod +x serp-api-archive/scripts/test_api.py

# Create a GitHub README template
echo "11. Creating GitHub README template..."
cat > serp-api-archive/docs/github_readme_template.md << 'EOL'
# SERP API (Archived Project)

![Status: Archived](https://img.shields.io/badge/Status-Archived-red)
![License: MIT](https://img.shields.io/badge/License-MIT-blue)

**IMPORTANT NOTICE: This project is archived and no longer maintained.**

This repository contains a simple API for searching Google and returning structured results. However, due to Google's anti-scraping measures, this approach is **not reliable for production use**.

## Why This Project Is Archived

This project was an experiment to create a simple search API by scraping Google results. However, it proved unreliable due to:

1. Google's anti-scraping measures
2. Frequent changes to Google's HTML structure
3. IP-based rate limiting and blocks
4. Inconsistent or empty results

**For reliable search APIs, please use official services like [Google Custom Search API](https://developers.google.com/custom-search) or third-party services like [SerpAPI](https://serpapi.com/).**

## Project Structure

This repository is maintained for **educational purposes only** to demonstrate:
- FastAPI implementation
- Web scraping challenges
- API design patterns

## Documentation

- [Installation Guide](docs/installation.md)
- [API Documentation](docs/api.md)
- [Limitations](docs/limitations.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
EOL

echo "12. Creating a zip archive..."
cd serp-api-archive
zip -r ../serp-api-archive.zip .
cd ..

echo "==============================================="
echo "Preparation complete!"
echo "The restructured codebase is in the 'serp-api-archive' directory."
echo "A zip file 'serp-api-archive.zip' has also been created."
echo ""
echo "Next steps for GitHub archiving:"
echo "1. Create a new GitHub repository"
echo "2. Upload the contents of the 'serp-api-archive' directory"
echo "3. In the GitHub repository settings, archive the repository"
echo ""
echo "The README.md clearly explains that this project doesn't work properly"
echo "and is being archived for educational purposes only."
echo "==============================================="