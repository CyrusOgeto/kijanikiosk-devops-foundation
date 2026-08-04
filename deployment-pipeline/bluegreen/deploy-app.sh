
#!/bin/bash
#Deployment script  to simulate health status
set -e

if [ -z "$APP_VERSION" ] || [ -z "$DEPLOY_ENV" ] || [ -z "$ARTIFACT_BASE_URL" ]; then
    echo "ERROR: APP_VERSION, DEPLOY_ENV, and ARTIFACT_BASE_URL must be set"
    exit 1
fi

echo "Deploying version $APP_VERSION to $DEPLOY_ENV environment"

TARGET_DIR="/opt/kijanikiosk/$DEPLOY_ENV"
sudo mkdir -p "$TARGET_DIR"

# Create a Python health server
sudo tee "$TARGET_DIR/app.py" << PY_EOF
#!/usr/bin/env python3
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

VERSION = "$APP_VERSION"
ENV = "$DEPLOY_ENV"
PORT = 3000 if ENV == "blue" else 3001

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            response = {
                "status": "healthy",
                "version": VERSION,
                "environment": ENV,
                "timestamp": "2026-08-04T00:00:00Z"
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    print(f"{ENV} server running on port {PORT} (version {VERSION})")
    HTTPServer(('', PORT), HealthHandler).serve_forever()
PY_EOF

sudo chown -R ubuntu:ubuntu "$TARGET_DIR"
sudo chmod +x "$TARGET_DIR/app.py"

sudo tee "/etc/systemd/system/kk-api-$DEPLOY_ENV.service" << SERVICE_EOF
[Unit]
Description=KijaniKiosk API $DEPLOY_ENV ($APP_VERSION)
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=$TARGET_DIR
ExecStart=/usr/bin/python3 $TARGET_DIR/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

sudo systemctl daemon-reload
sudo systemctl enable "kk-api-$DEPLOY_ENV.service"
sudo systemctl restart "kk-api-$DEPLOY_ENV.service"
sleep 2
sudo systemctl is-active "kk-api-$DEPLOY_ENV.service"

echo "Deployment of $APP_VERSION to $DEPLOY_ENV complete!"
PORT=$([ "$DEPLOY_ENV" = "blue" ] && echo "3000" || echo "3001")
echo "Service: kk-api-$DEPLOY_ENV.service on port $PORT"
