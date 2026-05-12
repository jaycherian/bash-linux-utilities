#!/bin/bash

# 1. Ensure the script is run with root privileges
if [[ "${EUID}" -ne 0 ]]; then
    echo "❌ Error: This script requires administrative privileges."
    echo "Please run it as root or using 'sudo $0'."
    exit 1
fi

# 2. Determine the target user
TARGET_USER="${SUDO_USER:-}"

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    read -p "Enter the username you want to configure for sudo: " TARGET_USER
fi

if ! id "$TARGET_USER" &>/dev/null; then
    echo "❌ Error: User '$TARGET_USER' does not exist."
    exit 1
fi

echo "⚙️ Configuring sudo access and password for: $TARGET_USER"

# 3. Interactively ask for and confirm the new password
while true; do
    read -s -p "Enter new sudo password for $TARGET_USER: " PASS1
    echo
    read -s -p "Confirm new password: " PASS2
    echo

    if [[ "$PASS1" == "$PASS2" ]]; then
        if [[ -z "$PASS1" ]]; then
            echo "⚠️ Password cannot be empty. Try again."
            continue
        fi
        break
    else
        echo "⚠️ Passwords do not match. Please try again."
    fi
done

# 4. Apply the new password
echo "$TARGET_USER:$PASS1" | chpasswd
if [[ $? -eq 0 ]]; then
    echo "✅ Password updated successfully."
else
    echo "❌ Failed to update password."
    exit 1
fi

# 5. Explicitly add the user to the sudoers file
SUDOERS_FILE="/etc/sudoers.d/$TARGET_USER"

# Write the rule giving the user full sudo access
echo "$TARGET_USER ALL=(ALL:ALL) ALL" > "$SUDOERS_FILE"

# Sudoers files MUST have exactly 0440 permissions to work securely
chmod 0440 "$SUDOERS_FILE"

# 6. Validate the new configuration safely
# visudo checks for syntax errors without breaking existing sudo access
if visudo -c -f "$SUDOERS_FILE" &>/dev/null; then
    echo "✅ Added explicit sudo privileges in $SUDOERS_FILE."
else
    echo "❌ Error: Invalid sudoers syntax. Reverting changes to prevent system lockout."
    rm -f "$SUDOERS_FILE"
    exit 1
fi

echo "🎉 Setup complete! $TARGET_USER is now explicitly in the sudoers file and can use sudo immediately."
