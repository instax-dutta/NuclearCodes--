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
