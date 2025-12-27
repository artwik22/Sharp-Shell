#!/bin/bash

# Notification server that intercepts D-Bus notifications
NOTIFICATION_FILE="/tmp/quickshell_notifications.json"

# Initialize empty array if file doesn't exist
if [ ! -f "$NOTIFICATION_FILE" ]; then
    echo "[]" > "$NOTIFICATION_FILE"
fi

# Function to escape JSON strings
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\$/\\$/g' | sed "s/'/\\'/g" | sed ':a;N;$!ba;s/\n/\\n/g'
}

# Function to add notification
add_notification() {
    local app_name="$1"
    local title="$2"
    local body="$3"
    local id=$(date +%s%N)
    local timestamp=$(date +%s)
    
    # Escape values
    app_name_esc=$(escape_json "$app_name")
    title_esc=$(escape_json "$title")
    body_esc=$(escape_json "$body")
    
    # Create notification JSON
    local notification="{\"id\":$id,\"appName\":\"$app_name_esc\",\"title\":\"$title_esc\",\"body\":\"$body_esc\",\"timestamp\":$timestamp}"
    
    # Read existing notifications
    local existing=$(cat "$NOTIFICATION_FILE" 2>/dev/null || echo "[]")
    
    # Add new notification (prepend, limit to 10)
    if command -v jq &> /dev/null; then
        echo "$existing" | jq --argjson new "$notification" '. = [$new] + . | .[:10]' > "$NOTIFICATION_FILE" 2>/dev/null || echo "[$notification]" > "$NOTIFICATION_FILE"
    else
        # Fallback without jq - simple prepend
        echo "[$notification]" > "$NOTIFICATION_FILE"
    fi
}

# Monitor D-Bus for notifications - improved parsing
dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null | while IFS= read -r line; do
    # Look for method call
    if echo "$line" | grep -q "method call.*Notify"; then
        # Buffer to collect all string parameters
        STRINGS=()
        
        # Read next 20 lines to collect all string parameters
        for i in {1..20}; do
            read -r param_line || break
            if echo "$param_line" | grep -q "string"; then
                VALUE=$(echo "$param_line" | sed -n 's/.*string "\([^"]*\)".*/\1/p')
                if [ -n "$VALUE" ]; then
                    STRINGS+=("$VALUE")
                fi
            fi
        done
        
        # Parse strings: usually [app_name, icon, title, body, ...]
        if [ ${#STRINGS[@]} -ge 3 ]; then
            APP_NAME="${STRINGS[0]}"
            TITLE="${STRINGS[2]}"
            BODY="${STRINGS[3]:-}"
            
            if [ -n "$TITLE" ]; then
                add_notification "${APP_NAME:-Unknown}" "$TITLE" "$BODY"
            fi
        fi
    fi
done
