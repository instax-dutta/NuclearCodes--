#!/bin/bash

# Exit on error
set -e

echo "Reverting SERP API changes and restoring original services"
echo "--------------------------------------------------------"

# Stop and disable the SERP API service
echo "Stopping and disabling SERP API service..."
sudo systemctl stop serp-api || true
sudo systemctl disable serp-api || true
sudo rm -f /etc/systemd/system/serp-api.service || true
sudo systemctl daemon-reload

# Remove Nginx configuration
echo "Removing Nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/serp.sdad.pro || true
sudo rm -f /etc/nginx/sites-available/serp.sdad.pro || true
sudo systemctl restart nginx || true

# Restart the original service that was using port 8080
echo "Attempting to restart services that might have been using port 8080..."
# List of common service names that might use port 8080
POSSIBLE_SERVICES=("apache2" "httpd" "tomcat" "jetty" "wildfly" "jboss" "nodejs" "nginx" "docker")

for service in "${POSSIBLE_SERVICES[@]}"; do
    if sudo systemctl list-unit-files | grep -q "$service"; then
        echo "Found $service, attempting to restart..."
        sudo systemctl restart $service || true
    fi
done

# Check what's currently using port 8080
echo "Checking what's currently using port 8080..."
sudo lsof -i :8080 || true
sudo netstat -tulpn | grep 8080 || true

echo "--------------------------------------------------------"
echo "Reversion complete. Please check if your original service is now accessible."
echo "If not, you may need to manually restart the specific service that was using port 8080."
echo ""
echo "To find out what service was using port 8080 before, you can check:"
echo "1. Your application logs"
echo "2. System journal: sudo journalctl | grep 8080"
echo "3. Process list: ps aux | grep <service-name>"
echo "--------------------------------------------------------"