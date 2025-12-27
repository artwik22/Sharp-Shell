#!/bin/bash

# Monitor D-Bus notifications and save to file
NOTIFICATION_FILE="/tmp/quickshell_notifications.json"

# Initialize empty array if file doesn't exist
if [ ! -f "$NOTIFICATION_FILE" ]; then
    echo "[]" > "$NOTIFICATION_FILE"
fi

# Function to escape JSON strings
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\$/\\$/g' | sed "s/'/\\'/g"
}

# Monitor D-Bus for notifications
dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null | while IFS= read -r line; do
    # Look for method call
    if echo "$line" | grep -q "method call"; then
        # Read notification parameters
        APP_NAME=""
        TITLE=""
        BODY=""
        
        # Read next lines to get parameters
        for i in {1..10}; do
            read -r param_line || break
            if echo "$param_line" | grep -q "string"; then
                VALUE=$(echo "$param_line" | sed -n 's/.*string "\([^"]*\)".*/\1/p')
                if [ -z "$APP_NAME" ]; then
                    APP_NAME="$VALUE"
                elif [ -z "$TITLE" ]; then
                    TITLE="$VALUE"
                elif [ -z "$BODY" ]; then
                    BODY="$VALUE"
                    break
                fi
            fi
        done
        
        if [ -n "$TITLE" ]; then
            # Escape values
            APP_NAME_ESC=$(escape_json "${APP_NAME:-Unknown}")
            TITLE_ESC=$(escape_json "$TITLE")
            BODY_ESC=$(escape_json "${BODY:-}")
            
            # Create notification JSON
            ID=$(date +%s%N)
            TIMESTAMP=$(date +%s)
            
            NOTIFICATION="{\"id\":$ID,\"appName\":\"$APP_NAME_ESC\",\"title\":\"$TITLE_ESC\",\"body\":\"$BODY_ESC\",\"timestamp\":$TIMESTAMP}"
            
            # Read existing notifications
            EXISTING=$(cat "$NOTIFICATION_FILE" 2>/dev/null || echo "[]")
            
            # Add new notification (prepend, limit to 10)
            if command -v jq &> /dev/null; then
                echo "$EXISTING" | jq --argjson new "$NOTIFICATION" '. = [$new] + . | .[:10]' > "$NOTIFICATION_FILE" 2>/dev/null
            else
                # Fallback without jq - simple prepend
                echo "[$NOTIFICATION]" > "$NOTIFICATION_FILE"
            fi
        fi
    fi
done
