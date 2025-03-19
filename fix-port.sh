#!/bin/bash

# Exit on error
set -e

echo "Fixing SERP API to use port 7777 instead of 8080"
echo "------------------------------------------------"

# Check if we're in the right directory
if [ "$(pwd)" != "/home/ubuntu/serp" ]; then
    echo "This script should be run from the /home/ubuntu/serp directory."
    echo "Current directory: $(pwd)"
    echo "Please change to the correct directory and try again."
    exit 1
fi

# Update .env file
echo "Updating .env file..."
echo "PORT=7777" > .env

# Update systemd service file
echo "Updating systemd service file..."
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
echo "Updating Nginx configuration..."
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

# Once you have SSL certificate, uncomment this section
# server {
#     listen 443 ssl;
#     server_name serp.sdad.pro;
#
#     ssl_certificate /etc/letsencrypt/live/serp.sdad.pro/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/serp.sdad.pro/privkey.pem;
#     include /etc/letsencrypt/options-ssl-nginx.conf;
#     ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
#
#     location / {
#         proxy_pass http://localhost:7777;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto $scheme;
#     }
# }
EOL

# Apply the changes
echo "Applying changes..."
sudo cp serp-api.service /etc/systemd/system/
sudo systemctl daemon-reload

# Check if the original service is running on port 8080
echo "Checking if port 8080 is in use..."
if sudo lsof -i :8080 || sudo netstat -tulpn | grep 8080; then
    echo "Port 8080 is still in use. This is good - your original service is running."
else
    echo "Port 8080 appears to be free. You may need to restart your original service manually."
fi

# Start the SERP API on port 7777
echo "Starting SERP API on port 7777..."
sudo systemctl restart serp-api || true

# Update Nginx configuration
echo "Updating Nginx configuration..."
sudo cp serp.sdad.pro /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/serp.sdad.pro /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

echo "------------------------------------------------"
echo "SERP API has been configured to use port 7777."
echo "Your original service on port 8080 should now be accessible again."
echo "The SERP API is available at: http://serp.sdad.pro (running on port 7777)"
echo "------------------------------------------------"
echo "To check the status of the SERP API service:"
echo "sudo systemctl status serp-api"
echo "------------------------------------------------"