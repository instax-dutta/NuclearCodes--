#!/bin/bash

# Exit on error
set -e

echo "Cleaning up temporary fix scripts..."

# Remove temporary fix scripts
rm -f fix-port.sh
rm -f revert-changes.sh
rm -f install-inplace.sh
rm -f install.sh

echo "Keeping only the necessary setup script..."
# Keep only setup-serp-api.sh and rename it to setup.sh
mv setup-serp-api.sh setup.sh
chmod +x setup.sh

echo "Cleanup complete. You now have a clean codebase with only the necessary files."
echo "To set up the SERP API, run: ./setup.sh"