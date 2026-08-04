#!/bin/bash
# kijanikiosk-provision.sh
# KijaniKiosk Foundation Provisioning Script
# Author: Cyrus Ogeto
# Date: 2026-06-25

set -euo pipefail

# ============================================
# DIRTY STATE DETECTION (from pre-provisioning audit)
# ============================================
# Expected dirty conditions found in pre-provisioning audit:
# - kk-api, kk-payments, kk-logs already exist (from Tuesday's lab)
# - /opt/kijanikiosk/config/ has chmod 777 (too permissive)
# - ufw has extra deny 3001 rule from Thursday remediation
# - curl is held (apt-mark hold curl)
# - /opt/kijanikiosk/shared/logs/ has permission issues
# ============================================

echo "============================================"
echo "KijaniKiosk Foundation Provisioning Script"
echo "============================================"
echo ""

# ============================================
# PHASE 1: Service Account Setup
# ============================================
echo "============================================"
echo "PHASE 1: Service Account Setup"
echo "============================================"

# Create group if it doesn't exist
if ! getent group kijanikiosk; then
    echo "Creating group: kijanikiosk"
    groupadd kijanikiosk
else
    echo "Group kijanikiosk already exists"
fi

# Create users if they don't exist
for user in kk-api kk-payments kk-logs; do
    if ! id "$user"; then
        echo "Creating user: $user"
        useradd -r -s /usr/sbin/nologin -d /dev/null -g kijanikiosk "$user"
    else
        echo "User $user already exists"
    fi
done

# Ensure users are in the group
echo "Adding users to kijanikiosk group"
usermod -aG kijanikiosk kk-api
usermod -aG kijanikiosk kk-payments
usermod -aG kijanikiosk kk-logs

echo "Phase 1 complete"
echo ""

# ============================================
# PHASE 2: Directory Structure & Permissions
# ============================================
echo "============================================"
echo "PHASE 2: Directory Structure & Permissions"
echo "============================================"

# Create directories
mkdir -p /opt/kijanikiosk/config
mkdir -p /opt/kijanikiosk/shared/logs
mkdir -p /opt/kijanikiosk/health
mkdir -p /opt/kijanikiosk/app

# Fix config directory permissions (remove 777 if present)
if [ -d /opt/kijanikiosk/config ]; then
    current_perms=$(stat -c %a /opt/kijanikiosk/config)
    if [ "$current_perms" = "777" ]; then
        echo "Fixing 777 permissions on /opt/kijanikiosk/config/"
        chmod 750 /opt/kijanikiosk/config/
    else
        echo "Permissions on /opt/kijanikiosk/config/ are correct"
    fi
fi

# Set correct ownership
chown root:kijanikiosk /opt/kijanikiosk/config/
chown root:kijanikiosk /opt/kijanikiosk/shared/logs/
chown kk-logs:kijanikiosk /opt/kijanikiosk/health/

# Set permissions
chmod 750 /opt/kijanikiosk/config/
chmod 1775 /opt/kijanikiosk/shared/logs/
chmod 750 /opt/kijanikiosk/health/
chmod 755 /opt/kijanikiosk/app/

# Set ACLs for log directory
setfacl -m g:kijanikiosk:rwx /opt/kijanikiosk/shared/logs/
setfacl -d -m g:kijanikiosk:rwx /opt/kijanikiosk/shared/logs/

echo "Phase 2 complete"
echo ""

# ============================================
# PHASE 3: Package Management
# ============================================
echo "============================================"
echo "PHASE 3: Package Management"
echo "============================================"

# Remove holds if they exist
if apt-mark showhold | grep -q curl; then
    echo "Removing hold on curl"
    apt-mark unhold curl
fi

# Update package lists
apt-get update -q

# Install required packages
apt-get install -y -q nginx curl lsof sysstat

# Pin specific versions (example)
apt-mark hold nginx

echo "Phase 3 complete"
echo ""

# ============================================
# PHASE 4: Configuration Files
# ============================================
echo "============================================"
echo "PHASE 4: Configuration Files"
echo "============================================"

# Create EnvironmentFile for kk-api
cat > /opt/kijanikiosk/config/api.env <<'EOF'
API_PORT=3000
API_ENV=production
LOG_LEVEL=info
EOF

# Create EnvironmentFile for kk-payments
cat > /opt/kijanikiosk/config/payments-api.env <<'EOF'
PAYMENTS_PORT=3001
PAYMENTS_ENV=production
DATABASE_URL=postgresql://localhost/payments
API_KEY=your-api-key-here
EOF

# Create EnvironmentFile for kk-logs
cat > /opt/kijanikiosk/config/logs.env <<'EOF'
LOGS_PORT=3002
LOGS_ENV=production
LOG_RETENTION_DAYS=7
EOF

# Set correct ownership and permissions
chown root:kijanikiosk /opt/kijanikiosk/config/*.env
chmod 640 /opt/kijanikiosk/config/*.env

echo "Phase 4 complete"
echo ""

# ============================================
# PHASE 5: Firewall Configuration
# ============================================
echo "============================================"
echo "PHASE 5: Firewall Configuration"
echo "============================================"

# Reset ufw to baseline
echo "Resetting UFW to baseline"
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Add rules with comments
ufw allow 22/tcp comment 'SSH access for administration'
ufw allow 80/tcp comment 'HTTP for web traffic'
ufw allow from 10.0.1.0/24 to any port 3001 comment 'Monitoring subnet access to payments health'
ufw deny 3001 comment 'Deny external access to payments service'

# Enable firewall
ufw --force enable

echo "Phase 5 complete"
echo ""

# ============================================
# PHASE 6: systemd Service Units
# ============================================
echo "============================================"
echo "PHASE 6: systemd Service Units"
echo "============================================"

# kk-api.service (target score < 3.5)
cat > /etc/systemd/system/kk-api.service <<'EOF'
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/app
EnvironmentFile=/opt/kijanikiosk/config/api.env
ExecStart=/usr/bin/python3 /opt/kijanikiosk/app/api.py
Restart=on-failure
RestartSec=10

# Hardening directives
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
ReadWritePaths=/opt/kijanikiosk/shared/logs

[Install]
WantedBy=multi-user.target
EOF

# kk-payments.service (target score < 2.5)
cat > /etc/systemd/system/kk-payments.service <<'EOF'
[Unit]
Description=KijaniKiosk Payments Service
After=kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/app
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/python3 /opt/kijanikiosk/app/payments.py
Restart=on-failure
RestartSec=10

# Hardening directives (strict for payments)
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
MemoryDenyWriteExecute=yes
ProtectControlGroups=yes
ProtectKernelModules=yes
ProtectKernelTunables=yes
RestrictRealtime=yes
RestrictNamespaces=yes
SystemCallArchitectures=native
ReadWritePaths=/opt/kijanikiosk/shared/logs

[Install]
WantedBy=multi-user.target
EOF

# kk-logs.service (target score < 3.5)
cat > /etc/systemd/system/kk-logs.service <<'EOF'
[Unit]
Description=KijaniKiosk Logs Service
After=network.target

[Service]
Type=simple
User=kk-logs
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/app
EnvironmentFile=/opt/kijanikiosk/config/logs.env
ExecStart=/usr/bin/python3 /opt/kijanikiosk/app/logs.py
Restart=on-failure
RestartSec=10

# Hardening directives
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
ReadWritePaths=/opt/kijanikiosk/shared/logs

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable services
systemctl daemon-reload
systemctl enable kk-api.service
systemctl enable kk-payments.service
systemctl enable kk-logs.service

# Start services (if they exist)
systemctl start kk-api.service 2>/dev/null || true
systemctl start kk-payments.service 2>/dev/null || true
systemctl start kk-logs.service 2>/dev/null || true

echo "Phase 6 complete"
echo ""

# ============================================
# PHASE 7: Journal Persistence & Log Rotation
# ============================================
echo "============================================"
echo "PHASE 7: Journal Persistence & Log Rotation"
echo "============================================"

# Configure journald for persistent storage
mkdir -p /var/log/journal
cat > /etc/systemd/journald.conf <<'EOF'
Storage=persistent
SystemMaxUse=500M
EOF

# Restart journald
systemctl restart systemd-journald

# Create logrotate config for all three services
cat > /etc/logrotate.d/kijanikiosk <<'EOF'
/opt/kijanikiosk/shared/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root kijanikiosk
    sharedscripts
    postrotate
        systemctl reload kk-logs.service >/dev/null 2>&1 || true
    endscript
}
EOF

# Verify logrotate config
logrotate --debug /etc/logrotate.d/kijanikiosk

echo "Phase 7 complete"
echo ""

# ============================================
# PHASE 8: Monitoring Health Checks
# ============================================
echo "============================================"
echo "PHASE 8: Monitoring Health Checks"
echo "============================================"

# Create health directory if not exists
mkdir -p /opt/kijanikiosk/health

# Check services and write JSON
api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')

printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s}\n' \
  "$(date -Iseconds)" "$api_status" "$payments_status" \
  > /opt/kijanikiosk/health/last-provision.json

chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
chmod 640 /opt/kijanikiosk/health/last-provision.json

echo "Phase 8 complete"
echo ""

# ============================================
# FINAL VERIFICATION
# ============================================
echo "============================================"
echo "FINAL VERIFICATION"
echo "============================================"

failed=0

# Check Phase 1: Users and group
echo -n "Checking Phase 1: "
if getent group kijanikiosk >/dev/null 2>&1 && \
   id kk-api >/dev/null 2>&1 && \
   id kk-payments >/dev/null 2>&1 && \
   id kk-logs >/dev/null 2>&1; then
    echo "PASS: Users and group exist"
else
    echo "FAIL: Users or group missing"
    failed=$((failed + 1))
fi

# Check Phase 2: Directories and permissions
echo -n "Checking Phase 2: "
if [ -d /opt/kijanikiosk/config ] && \
   [ -d /opt/kijanikiosk/shared/logs ] && \
   [ -d /opt/kijanikiosk/health ] && \
   [ -d /opt/kijanikiosk/app ]; then
    echo "PASS: All directories exist"
else
    echo "FAIL: Directories missing"
    failed=$((failed + 1))
fi

# Check Phase 3: Packages
echo -n "Checking Phase 3: "
if dpkg -l nginx >/dev/null 2>&1 && \
   dpkg -l curl >/dev/null 2>&1; then
    echo "PASS: Required packages installed"
else
    echo "FAIL: Packages missing"
    failed=$((failed + 1))
fi

# Check Phase 4: Config files
echo -n "Checking Phase 4: "
if [ -f /opt/kijanikiosk/config/api.env ] && \
   [ -f /opt/kijanikiosk/config/payments-api.env ] && \
   [ -f /opt/kijanikiosk/config/logs.env ]; then
    echo "PASS: Config files exist"
else
    echo "FAIL: Config files missing"
    failed=$((failed + 1))
fi

# Check Phase 5: Firewall
echo -n "Checking Phase 5: "
if ufw status | grep -q "22.*ALLOW" && \
   ufw status | grep -q "80.*ALLOW" && \
   ufw status | grep -q "3001.*DENY"; then
    echo "PASS: Firewall rules correct"
else
    echo "FAIL: Firewall rules incorrect"
    failed=$((failed + 1))
fi

# Check Phase 6: Services
echo -n "Checking Phase 6: "
if systemctl is-enabled kk-api.service >/dev/null 2>&1 && \
   systemctl is-enabled kk-payments.service >/dev/null 2>&1 && \
   systemctl is-enabled kk-logs.service >/dev/null 2>&1; then
    echo "PASS: Services enabled"
else
    echo "FAIL: Services not enabled"
    failed=$((failed + 1))
fi

# Check Phase 7: Logrotate
echo -n "Checking Phase 7: "
if logrotate --debug /etc/logrotate.d/kijanikiosk >/dev/null 2>&1; then
    echo "PASS: Logrotate config valid"
else
    echo "FAIL: Logrotate config invalid"
    failed=$((failed + 1))
fi

# Check Phase 8: Health check file
echo -n "Checking Phase 8: "
if [ -f /opt/kijanikiosk/health/last-provision.json ]; then
    echo "PASS: Health check file exists"
else
    echo "FAIL: Health check file missing"
    failed=$((failed + 1))
fi

echo ""
echo "============================================"
if [ $failed -eq 0 ]; then
    echo "ALL CHECKS PASSED ✅"
    echo "Provisioning complete!"
    exit 0
else
    echo "$failed CHECK(S) FAILED ❌"
    echo "Please review the failures above"
    exit 1
fi
echo "============================================"
