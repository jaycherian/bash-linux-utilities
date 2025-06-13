#!/bin/bash

# ==============================================================================
#
# Title:        Interactive Chrome Remote Desktop Setup Script for Ubuntu
# Description:  This script automates the installation and configuration of
#               Chrome Remote Desktop with the KDE Plasma desktop environment.
# Author:       Gemini
#
# ==============================================================================

# --- Configuration and Helpers ---
# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors for output messages
COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m' # No Color

# --- Functions ---

# Helper function to print a step header
print_step() {
  echo -e "\n${COLOR_BLUE}>>> Step: $1...${COLOR_NC}"
}

# Helper function for user confirmation
confirm() {
  # call with a prompt string or use a default
  read -r -p "$(echo -e "${COLOR_YELLOW}$1 [y/N] ${NC}")" response
  case "$response" in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

# Function to check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${COLOR_RED}Error: This script must be run as root. Please use sudo.${COLOR_NC}"
        exit 1
    fi
}

# --- Main Script Logic ---

# 1. Welcome and Initial Check
clear
echo -e "${COLOR_GREEN}==============================================================${NC}"
echo -e "${COLOR_GREEN}  Interactive Chrome Remote Desktop Setup Script for Ubuntu   ${NC}"
echo -e "${COLOR_GREEN}==============================================================${NC}"
echo -e "This script will guide you through the following steps:"
echo "  1. Update system packages."
echo "  2. Add the Google Chrome and Remote Desktop repositories."
echo "  3. Install the Chrome Remote Desktop host service."
echo "  4. Install the KDE Plasma Desktop Environment."
echo "  5. Configure the session for KDE Plasma."
echo "  6. Install the Google Chrome browser."
echo

# Ensure the script is being run with sudo
check_root

# 2. Update Ubuntu Packages
print_step "Updating System Packages"
if confirm "Do you want to update and upgrade your system packages?"; then
  echo "Updating package lists..."
  apt-get update
  echo "Upgrading installed packages..."
  apt-get upgrade -y
  echo -e "${COLOR_GREEN}System packages updated successfully.${NC}"
else
  echo -e "${COLOR_YELLOW}Skipping package updates. This might cause issues later.${NC}"
fi

# 3. Add Google's Repository
print_step "Adding Google's Official Repository"
if confirm "Do you want to add the Google repository for Chrome Remote Desktop?"; then
  echo "Downloading Google's Linux signing key..."
  curl https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/chrome-remote-desktop.gpg

  echo "Adding the Chrome Remote Desktop repository source..."
  echo "deb [arch=amd64] https://dl.google.com/linux/chrome-remote-desktop/deb stable main" \
    | tee /etc/apt/sources.list.d/chrome-remote-desktop.list

  echo "Refreshing package lists after adding the repository..."
  apt-get update
  echo -e "${COLOR_GREEN}Google repository added successfully.${NC}"
else
  echo -e "${COLOR_RED}Cannot proceed without the repository. Exiting script.${NC}"
  exit 1
fi

# 4. Install Chrome Remote Desktop and Desktop Environment
print_step "Installing Host Service and Desktop Environment"
if confirm "Do you want to install the Chrome Remote Desktop host service?"; then
  echo "Installing Chrome Remote Desktop..."
  # Use non-interactive frontend to prevent prompts during installation
  DEBIAN_FRONTEND=noninteractive \
    apt-get install --assume-yes chrome-remote-desktop
  echo -e "${COLOR_GREEN}Chrome Remote Desktop installed successfully.${NC}"
else
  echo -e "${COLOR_RED}Cannot proceed without the host service. Exiting script.${NC}"
  exit 1
fi

echo
if confirm "Do you want to install the KDE Plasma desktop environment? (This is a large download)"; then
  echo "Installing KDE Plasma (kde-full)... This will take a while."
  DEBIAN_FRONTEND=noninteractive \
    apt-get install --assume-yes kde-full
  echo -e "${COLOR_GREEN}KDE Plasma installed successfully.${NC}"
else
  echo -e "${COLOR_RED}A desktop environment is required. Exiting script.${NC}"
  exit 1
fi

# 5. Configure Session
print_step "Configuring the Remote Session"
if confirm "Do you want to configure Chrome Remote Desktop to use KDE Plasma?"; then
  echo "Setting KDE Plasma as the default session..."
  bash -c 'echo "exec /etc/X11/Xsession /usr/bin/startplasma-x11" > /etc/chrome-remote-desktop-session'
  echo -e "${COLOR_GREEN}Session configured successfully.${NC}"
else
  echo -e "${COLOR_YELLOW}Skipping session configuration. You will need to set this manually.${NC}"
fi

# 6. Install Google Chrome Browser
print_step "Installing Google Chrome Browser"
if confirm "Do you want to download and install Google Chrome? (Required for setup)"; then
  echo "Downloading Google Chrome..."
  curl -L -o google-chrome-stable_current_amd64.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  
  echo "Installing Google Chrome..."
  apt-get install --assume-yes --fix-broken ./google-chrome-stable_current_amd64.deb
  
  echo "Cleaning up installer file..."
  rm google-chrome-stable_current_amd64.deb
  
  echo -e "${COLOR_GREEN}Google Chrome installed successfully.${NC}"
else
  echo -e "${COLOR_YELLOW}Skipping Google Chrome installation. It is required to authorize the remote desktop service.${NC}"
fi


# 7. Completion Message
echo -e "\n${COLOR_GREEN}===========================================${NC}"
echo -e "${COLOR_GREEN}  Chrome Remote Desktop Setup Complete!    ${NC}"
echo -e "${COLOR_GREEN}===========================================${NC}"
echo "Summary:"
echo " - System packages are up to date."
echo " - Chrome Remote Desktop and KDE Plasma are installed."
echo " - Google Chrome browser has been installed."
echo
echo -e "${COLOR_YELLOW}NEXT STEPS ARE CRITICAL:${NC}"
echo "1. Go to the Chrome Remote Desktop website on your local machine:"
echo "   ${COLOR_GREEN}https://remotedesktop.google.com/headless${NC}"
echo "2. Click 'Begin', then 'Next', then 'Authorize'."
echo "3. Copy the command provided for 'Debian Linux'."
echo "4. Paste and run that command in this machine's terminal."
echo "5. Choose a name and a PIN for your computer when prompted."
echo
echo "Your remote desktop session should then be accessible."

exit 0

