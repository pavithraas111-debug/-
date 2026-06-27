#!/bin/bash

# SSH Honeypot Monitor Deployment Script
# This script automates the deployment of the honeypot monitor as a systemd service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/honeypot-monitor"
SERVICE_NAME="honeypot-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}SSH Honeypot Monitor Deployment Script${NC}"
echo "========================================"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Step 1: Install dependencies
echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
apt-get update
apt-get install -y python3 python3-pip

# Step 2: Create installation directory
echo -e "${YELLOW}[2/5] Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/honeypot_monitor.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"

# Step 3: Install Python requirements
echo -e "${YELLOW}[3/5] Installing Python dependencies...${NC}"
pip3 install -r "$INSTALL_DIR/requirements.txt"

# Step 4: Create systemd service file
echo -e "${YELLOW}[4/5] Creating systemd service...${NC}"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=SSH Honeypot Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/honeypot_monitor.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Step 5: Enable and start service
echo -e "${YELLOW}[5/5] Enabling and starting service...${NC}"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Verify installation
sleep 2
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo -e "${GREEN}✓ Deployment successful!${NC}"
    echo ""
    echo "Service Details:"
    echo "  Service name: $SERVICE_NAME"
    echo "  Installation directory: $INSTALL_DIR"
    echo "  Service file: $SERVICE_FILE"
    echo ""
    echo "Useful commands:"
    echo "  Check status:  sudo systemctl status $SERVICE_NAME"
    echo "  View logs:     sudo journalctl -u $SERVICE_NAME -f"
    echo "  Stop service:  sudo systemctl stop $SERVICE_NAME"
    echo "  Restart:       sudo systemctl restart $SERVICE_NAME"
else
    echo -e "${RED}✗ Service failed to start. Check logs with:${NC}"
    echo "  sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi