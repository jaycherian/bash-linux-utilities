#!/bin/bash

# ==============================================================================
#
# Title:        Interactive Python 3.11 Upgrade Script for Ubuntu
# Description:  This script automates the process of installing Python 3.11 and
#               setting it as the default python3 version on Ubuntu systems.
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
echo -e "${COLOR_GREEN}=====================================================${NC}"
echo -e "${COLOR_GREEN}  Python 3.11 Interactive Upgrade Script for Ubuntu  ${NC}"
echo -e "${COLOR_GREEN}=====================================================${NC}"
echo -e "This script will guide you through the following steps:"
echo "  1. Update system packages."
echo "  2. Add the 'deadsnakes' PPA for newer Python versions."
echo "  3. Install Python 3.11 and essential related packages."
echo "  4. Verify the installation."
echo "  5. Configure Python 3.11 as the default 'python3'."
echo "  6. Install 'python-is-python3' for convenience."
echo

# Ensure the script is being run with sudo
check_root

# 2. Update Ubuntu Packages
print_step "Updating System Packages"
if confirm "Do you want to update and upgrade your system packages?"; then
  echo "Updating package lists..."
  apt update
  echo "Upgrading installed packages..."
  apt upgrade -y
  echo -e "${COLOR_GREEN}System packages updated successfully.${NC}"
else
  echo -e "${COLOR_YELLOW}Skipping package updates. This might cause issues later.${NC}"
fi

# 3. Add the Deadsnakes PPA
print_step "Adding the Deadsnakes PPA"
if confirm "Do you want to add the 'deadsnakes/ppa' repository to get Python 3.11?"; then
  echo "Adding required 'software-properties-common' package..."
  apt install -y software-properties-common
  echo "Adding the PPA..."
  add-apt-repository ppa:deadsnakes/ppa -y
  echo "Refreshing package lists after adding PPA..."
  apt update
  echo -e "${COLOR_GREEN}Deadsnakes PPA added successfully.${NC}"
else
  echo -e "${COLOR_RED}Cannot proceed without the PPA. Exiting script.${NC}"
  exit 1
fi

# 4. Install Python 3.11
print_step "Installing Python 3.11"
if confirm "Do you want to install Python 3.11?"; then
  echo "Installing Python 3.11 and related packages (dev, venv, pip)..."
  apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
  echo -e "${COLOR_GREEN}Python 3.11 installed successfully.${NC}"
else
  echo -e "${COLOR_RED}Cannot proceed without installing Python 3.11. Exiting script.${NC}"
  exit 1
fi

# 5. Verify Installation
print_step "Verifying Python 3.11 Installation"
echo "Running 'python3.11 --version' to confirm:"
python3.11 --version
echo -e "${COLOR_GREEN}Verification complete.${NC}"
sleep 2

# 6. Set Python 3.11 as Default
print_step "Setting Python 3.11 as the Default 'python3'"
if confirm "Do you want to configure python3.11 as the default version for the 'python3' command?"; then
  # Find other python3 versions and add them to update-alternatives with lower priority
  for version_path in /usr/bin/python3.*; do
    if [[ "$version_path" != "/usr/bin/python3.11" ]]; then
      # Extract version number like 3.10 from /usr/bin/python3.10
      version_num=$(basename "$version_path")
      echo "Registering existing version '$version_num' with priority 1..."
      update-alternatives --install /usr/bin/python3 python3 "$version_path" 1
    fi
  done

  # Install Python 3.11 with a higher priority
  echo "Registering python3.11 with priority 2..."
  update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2

  # Let the user choose interactively
  echo -e "\n${COLOR_YELLOW}You will now be prompted to choose the default version.${NC}"
  echo -e "Please select the number corresponding to ${COLOR_GREEN}/usr/bin/python3.11${NC}."
  sleep 3
  update-alternatives --config python3

  echo -e "\nVerifying the new default version..."
  echo "Output of 'python3 --version':"
  python3 --version
  echo -e "${COLOR_GREEN}Default Python version updated.${NC}"
else
  echo -e "${COLOR_YELLOW}Skipping configuration of the default Python version.${NC}"
fi

# 7. Install python-is-python3
print_step "Installing 'python-is-python3'"
if confirm "Do you want to install 'python-is-python3'? This links the 'python' command to 'python3'."; then
  echo "Installing 'python-is-python3'..."
  apt install -y python-is-python3
  echo -e "\nVerifying the 'python' command..."
  echo "Output of 'python --version':"
  python --version
  echo -e "${COLOR_GREEN}'python-is-python3' installed successfully.${NC}"
else
  echo -e "${COLOR_YELLOW}Skipping installation of 'python-is-python3'.${NC}"
fi

# 8. Completion Message
echo -e "\n${COLOR_GREEN}===========================================${NC}"
echo -e "${COLOR_GREEN}  Python 3.11 Upgrade Process Complete!  ${NC}"
echo -e "${COLOR_GREEN}===========================================${NC}"
echo "Summary:"
echo " - System packages are up to date."
echo " - Python 3.11 has been installed."
echo " - Default versions may have been updated based on your choices."
echo
echo "Enjoy coding with Python 3.11!"

exit 0

