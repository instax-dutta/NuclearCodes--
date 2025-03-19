#!/bin/bash

# Exit on error
set -e

echo "Setting up SERP API on port 7777"
echo "--------------------------------"

# Check if we're in the right directory
if [ "$(pwd)" != "/home/ubuntu/serp" ]; then
    echo "This script should be run from the /home/ubuntu/serp directory."
    echo "Current directory: $(pwd)"
    echo "Please change to the correct directory and try again."
    exit 1
fi

# Update system packages
echo "Updating system packages..."
sudo apt update
sudo apt install -y python3-pip python3-venv nginx

# Ensure .env file has the correct port
echo "Configuring environment..."
echo "PORT=7777" > .env

# Create and activate virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Update systemd service file
echo "Configuring systemd service..."
cat > serp-api.service << 'EOL'
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

# Update Nginx configuration
echo "Configuring Nginx..."
cat > serp.sdad.pro << 'EOL'
server {
    listen 80;
    server_name serp.sdad.pro;

    location / {
        proxy_pass http://localhost:7777;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL

# Apply the configurations
echo "Applying configurations..."
sudo cp serp-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable serp-api
sudo systemctl start serp-api

sudo cp serp.sdad.pro /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/serp.sdad.pro /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# Check if the service is running
echo "Checking if SERP API is running..."
if sudo systemctl is-active --quiet serp-api; then
    echo "✅ SERP API service is running."
else
    echo "❌ SERP API service failed to start. Checking logs..."
    sudo systemctl status serp-api
fi

# Check if port 7777 is in use
echo "Checking if port 7777 is in use..."
if sudo lsof -i :7777 || sudo netstat -tulpn | grep 7777; then
    echo "✅ Port 7777 is in use by the SERP API."
else
    echo "❌ Port 7777 is not in use. Something went wrong."
fi

echo "--------------------------------"
echo "SERP API setup is complete!"
echo "Your API is available at: http://serp.sdad.pro"
echo "--------------------------------"
echo "API Usage Examples:"
echo "GET: curl -X GET \"http://serp.sdad.pro/search?query=example\""
echo "POST: curl -X POST \"http://serp.sdad.pro/search\" -H \"Content-Type: application/json\" -d '{\"query\":\"example\"}'"
echo "--------------------------------"
echo "To check the logs: tail -f /home/ubuntu/serp/serp_api.log"
echo "To check the service status: sudo systemctl status serp-api"
echo "--------------------------------"

# Ask if user wants to set up SSL
echo "Do you want to set up SSL with Let's Encrypt? (y/n)"
read setup_ssl

if [ "$setup_ssl" = "y" ]; then
    echo "Setting up SSL with Let's Encrypt..."
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d serp.sdad.pro
    
    echo "SSL setup complete. Your API is now available at: https://serp.sdad.pro"
fi