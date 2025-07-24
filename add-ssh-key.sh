#!/bin/bash

# Script to add an SSH public key to the current user's authorized_keys file
# and set correct permissions for secure SSH access.

echo "--- SSH Key Addition Script ---"
echo "This script will add a new SSH public key to your authorized_keys file."
echo "Please paste your FULL SSH public key below (it should start with 'ssh-rsa', 'ssh-ed25519', etc. and include the comment at the end)."
echo ""
echo "When you are done pasting, press Enter to go to a new line, then type:"
echo "END_SSH_KEY"
echo "and press Enter again to submit."
echo "-------------------------------"

# Define the end marker for input
END_MARKER="END_SSH_KEY"

# Read the public key from standard input until the END_MARKER is encountered
PUBLIC_KEY_INPUT=""
while IFS= read -r line; do
    if [[ "$line" == "$END_MARKER" ]]; then
        break
    fi
    # Append line and a newline, avoiding an extra newline at the very end if input ends precisely with the marker
    if [ -n "$PUBLIC_KEY_INPUT" ]; then
        PUBLIC_KEY_INPUT+=$'\n'
    fi
    PUBLIC_KEY_INPUT+="$line"
done

# Check if any input was received
if [ -z "$PUBLIC_KEY_INPUT" ]; then
    echo "Error: No public key was provided. Exiting."
    exit 1
fi

# Determine the current user's home directory
USER_HOME=$(eval echo ~$(whoami))
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS_FILE="$SSH_DIR/authorized_keys"

echo "Attempting to add key for user: $(whoami)"
echo "Target .ssh directory: $SSH_DIR"
echo "Target authorized_keys file: $AUTHORIZED_KEYS_FILE"

# 1. Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "Creating directory: $SSH_DIR"
    mkdir -p "$SSH_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create '$SSH_DIR'. Check your user's permissions."
        exit 1
    fi
else
    echo "Directory '$SSH_DIR' already exists."
fi

# 2. Set strict permissions for the .ssh directory (drwx------)
echo "Setting permissions for '$SSH_DIR' to 700 (owner read, write, execute only)."
chmod 700 "$SSH_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for '$SSH_DIR'. Check permissions."
    exit 1
fi

# 3. Append the public key to authorized_keys
echo "Appending public key to '$AUTHORIZED_KEYS_FILE'..."
echo "$PUBLIC_KEY_INPUT" >> "$AUTHORIZED_KEYS_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to append key to '$AUTHORIZED_KEYS_FILE'. Check permissions."
    exit 1
fi

# 4. Set strict permissions for the authorized_keys file (-rw-------)
echo "Setting permissions for '$AUTHORIZED_KEYS_FILE' to 600 (owner read, write only)."
chmod 600 "$AUTHORIZED_KEYS_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to set permissions for '$AUTHORIZED_KEYS_FILE'. Check permissions."
    exit 1
fi

echo "--- Script Completed ---"
echo "Public key successfully added and permissions set."
echo "You should now be able to SSH into this VM using your corresponding private key."
echo "-----------------------"
echo "Next step: From your local machine, try connecting:"
echo "ssh $(whoami)@your_vm_ip_or_hostname"
echo ""
echo "Important: If you set a passphrase for your SSH key, you will be prompted for it when connecting."
echo "For enhanced security, consider disabling password authentication in /etc/ssh/sshd_config on this VM, but ONLY AFTER you've confirmed SSH key access works flawlessly."
