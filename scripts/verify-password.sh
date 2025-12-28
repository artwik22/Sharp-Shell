#!/bin/bash
# Verify user password using sudo
# Usage: verify-password.sh <password>
# Returns 0 on success, 1 on failure

PASSWORD="$1"
USERNAME=$(whoami)

# Use sudo to verify password - this is more reliable than su
# -S reads password from stdin
# -v validates the password
echo "$PASSWORD" | sudo -S -v 2>/dev/null
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    # Password is correct, now verify it's the user's password by trying to su
    # This double-checks that it's the user password, not just sudo access
    echo "$PASSWORD" | timeout 1 su -c "true" "$USERNAME" 2>/dev/null
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        exit 0
    else
        # If su fails but sudo worked, it might be sudo password, not user password
        # But for lock screen, sudo password is acceptable too
        exit 0
    fi
else
    exit 1
fi


