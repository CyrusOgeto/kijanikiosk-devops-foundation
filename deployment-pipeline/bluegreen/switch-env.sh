#!/bin/bash
# KijaniKiosk Environment Switch Script
# Usage: sudo bash /opt/kijanikiosk/scripts/switch-env.sh [blue|green]

set -e

TARGET_ENV="$1"
ACTIVE_ENV_FILE="/opt/kijanikiosk/.active-env"
PREVIOUS_ENV_FILE="/opt/kijanikiosk/.previous-env"

if [ -z "$TARGET_ENV" ] || { [ "$TARGET_ENV" != "blue" ] && [ "$TARGET_ENV" != "green" ]; }; then
    echo "Usage: $0 [blue|green]"
    exit 1
fi

# Get current active environment if it exists
CURRENT_ENV=""
if [ -f "$ACTIVE_ENV_FILE" ]; then
    CURRENT_ENV=$(cat "$ACTIVE_ENV_FILE")
fi

# Determine the port based on target
TARGET_PORT=$([ "$TARGET_ENV" = "blue" ] && echo "3000" || echo "3001")
ACTIVE_PORT=$([ "$CURRENT_ENV" = "blue" ] && echo "3000" || echo "3001")

echo "Switching from ${CURRENT_ENV:-unknown} to $TARGET_ENV..."

# Check if target service is running and healthy
echo "Checking target service (kk-api-$TARGET_ENV) health..."
if ! systemctl is-active "kk-api-$TARGET_ENV.service" >/dev/null 2>&1; then
    echo "Error: kk-api-$TARGET_ENV.service is not running"
    exit 1
fi

# Health check on target service
HEALTH_URL="http://127.0.0.1:$TARGET_PORT/health"
if ! curl -s -f "$HEALTH_URL" > /dev/null; then
    echo "Error: Target service health check failed"
    exit 1
fi

# Update nginx configuration
echo "Updating nginx configuration..."
cat > /etc/nginx/sites-available/kijanikiosk << NGINX_EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$TARGET_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_EOF

# Test and reload nginx
nginx -t && systemctl reload nginx

# Update state files
echo "Updating state files..."
if [ -f "$ACTIVE_ENV_FILE" ]; then
    echo "$CURRENT_ENV" > "$PREVIOUS_ENV_FILE"
fi
echo "$TARGET_ENV" > "$ACTIVE_ENV_FILE"

echo "Switch to $TARGET_ENV complete!"
echo "Active: $TARGET_ENV"
echo "Previous: $CURRENT_ENV"
echo "Port: $TARGET_PORT"
echo "Health URL: http://127.0.0.1:80/health"
