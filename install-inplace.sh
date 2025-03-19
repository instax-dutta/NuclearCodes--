#!/bin/bash

# Exit on error
set -e

echo "Setting up SERP API on AWS Lightsail Ubuntu VM"
echo "----------------------------------------------"

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
sudo apt upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt install -y python3-pip python3-venv nginx certbot python3-certbot-nginx

# Create and activate virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Set up systemd service
echo "Setting up systemd service..."
sudo cp serp-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable serp-api
sudo systemctl start serp-api

# Set up Nginx
echo "Setting up Nginx..."
sudo cp serp.sdad.pro /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/serp.sdad.pro /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Set up SSL with Let's Encrypt
echo "Do you want to set up SSL with Let's Encrypt? (y/n)"
read setup_ssl

if [ "$setup_ssl" = "y" ]; then
    echo "Setting up SSL with Let's Encrypt..."
    sudo certbot --nginx -d serp.sdad.pro
    
    # Enable HTTPS in Nginx config
    sudo sed -i 's/# server {/server {/g' /etc/nginx/sites-available/serp.sdad.pro
    sudo sed -i 's/# listen 443/listen 443/g' /etc/nginx/sites-available/serp.sdad.pro
    sudo sed -i 's/# ssl_certificate/ssl_certificate/g' /etc/nginx/sites-available/serp.sdad.pro
    sudo sed -i 's/# ssl_certificate_key/ssl_certificate_key/g' /etc/nginx/sites-available/serp.sdad.pro
    sudo sed -i 's/# include \/etc\/letsencrypt/include \/etc\/letsencrypt/g' /etc/nginx/sites-available/serp.sdad.pro
    sudo sed -i 's/# ssl_dhparam/ssl_dhparam/g' /etc/nginx/sites-available/serp.sdad.pro
    
    sudo nginx -t
    sudo systemctl restart nginx
fi

echo "----------------------------------------------"
echo "SERP API setup complete!"
echo "Your API is now available at: http://serp.sdad.pro (running on port 7777)"
if [ "$setup_ssl" = "y" ]; then
    echo "Your API is also available securely at: https://serp.sdad.pro (running on port 7777)"
fi
echo "----------------------------------------------"
echo "API Usage Examples:"
echo "GET: curl -X GET \"http://serp.sdad.pro/search?query=example\""
echo "POST: curl -X POST \"http://serp.sdad.pro/search\" -H \"Content-Type: application/json\" -d '{\"query\":\"example\"}'"
echo "----------------------------------------------"