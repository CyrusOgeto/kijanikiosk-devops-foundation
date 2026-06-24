#!/bin/bash
# kijanikiosk-provision.sh
# KijaniKiosk Foundation Provisioning Script
# Phase 1: Service Account Setup

set -euo pipefail

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
