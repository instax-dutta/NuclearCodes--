# SERP API

A self-hosted Search Engine Results Page (SERP) API for retrieving search results from Google.

## Features

- Search Google and get results in JSON format
- Free to use with no API key required
- Configurable number of results, language, and country
- Easy deployment on AWS Lightsail Ubuntu VM (running on port 7777)
- Automatic SSL setup with Let's Encrypt

## Setup Instructions

### Prerequisites

- AWS Lightsail Ubuntu VM
- Domain name (serp.sdad.pro) with DNS pointing to your VM's IP address
- Basic knowledge of Linux commands

### Installation

1. Connect to your AWS Lightsail Ubuntu VM via SSH:

```bash
ssh ubuntu@your-lightsail-ip
```

2. Clone or copy the project files to your VM:

```bash
mkdir -p ~/serp-api-setup
cd ~/serp-api-setup
# Copy all files to this directory
```

3. Make the setup script executable:

```bash
chmod +x setup.sh
```

4. Update the paths in the setup script:

```bash
nano setup.sh
# Update the paths to point to your actual file locations
```

5. Run the setup script:

```bash
./setup.sh
```

6. Follow the prompts to complete the installation.

### Manual Setup (if script fails)

If the automated script fails, you can follow these manual steps:

1. Update system packages:

```bash
sudo apt update
sudo apt upgrade -y
```

2. Install required packages:

```bash
sudo apt install -y python3-pip python3-venv nginx certbot python3-certbot-nginx
```

3. Create project directory:

```bash
mkdir -p ~/serp-api
cd ~/serp-api
```

4. Copy project files:

```bash
# Copy the files to the project directory
```

5. Create and activate virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
```

6. Install dependencies:

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

7. Set up systemd service:

```bash
sudo cp serp-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable serp-api
sudo systemctl start serp-api
```

8. Set up Nginx:

```bash
sudo cp serp.sdad.pro /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/serp.sdad.pro /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

9. Set up SSL with Let's Encrypt:

```bash
sudo certbot --nginx -d serp.sdad.pro
```

## API Usage

### Endpoints

#### GET /search

```
GET /search?query=example&num_results=10&language=en&country=us
```

Parameters:
- `query`: Search query (required)
- `num_results`: Number of results to return (default: 10)
- `language`: Language code (default: en)
- `country`: Country code (default: us)

#### POST /search

```
POST /search
Content-Type: application/json

{
  "query": "example",
  "num_results": 10,
  "language": "en",
  "country": "us"
}
```

### Example Response

```json
{
  "query": "example",
  "results_count": 10,
  "results": [
    {
      "title": "Example Title",
      "link": "https://example.com",
      "snippet": "This is an example snippet from the search results..."
    },
    ...
  ]
}
```

## Troubleshooting

### Check Service Status

```bash
sudo systemctl status serp-api
```

### View Logs

```bash
sudo journalctl -u serp-api
```

### Nginx Logs

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### API Logs

```bash
tail -f ~/serp/serp_api.log
```

## Security Considerations

- Consider implementing rate limiting for production use
- Regularly update dependencies for security patches
- Use HTTPS for all API requests in production

## License

This project is licensed under the MIT License - see the LICENSE file for details.