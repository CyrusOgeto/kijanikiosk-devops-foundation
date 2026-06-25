# KijaniKiosk Access Model - Final

## Overview
This document defines the access control model for the KijaniKiosk infrastructure, including user accounts, group memberships, directory permissions, and ACLs.

## Users and Groups

| User | Group | Purpose |
|------|-------|---------|
| kk-api | kijanikiosk | API service account |
| kk-payments | kijanikiosk | Payments service account |
| kk-logs | kijanikiosk | Logging service account |

## Directory Structure and Permissions

| Path | Owner | Group | Permissions | ACLs |
|------|-------|-------|-------------|------|
| /opt/kijanikiosk/ | root | root | 755 | None |

> **755** = Owner (root) can read/write/execute (7), Group (root) can read/execute (5), Others can read/execute (5). Standard for application root directories.

| /opt/kijanikiosk/config/ | root | kijanikiosk | 750 | None |

> **750** = Owner (root) can read/write/execute (7), Group (kijanikiosk) can read/execute (5), Others have no access (0). Config files contain sensitive data so only the group should access them.

| /opt/kijanikiosk/shared/logs/ | root | kijanikiosk | 1775 | g:kijanikiosk:rwx (default) |

> **1775** = Sticky bit (1) prevents users from deleting each other's files. Owner (root) has full access (7), Group (kijanikiosk) can read/write/execute (7), Others have read/execute (5). The sticky bit ensures logs are shared but protected from accidental deletion.

| /opt/kijanikiosk/health/ | kk-logs | kijanikiosk | 750 | None |

> **750** = Owner (kk-logs) can read/write/execute (7), Group (kijanikiosk) can read/execute (5), Others have no access (0). Health checks are written by kk-logs and read by monitoring tools in the same group.

| /opt/kijanikiosk/app/ | root | root | 755 | None |

> **755** = Owner (root) can read/write/execute (7), Group (root) can read/execute (5), Others can read/execute (5). Standard for application code directories where the service needs to execute scripts.

## Permission Reference (Octal Values)

| Octal | Permission | Meaning |
|-------|------------|---------|
| 7 | rwx | Read, Write, Execute |
| 6 | rw- | Read, Write |
| 5 | r-x | Read, Execute |
| 4 | r-- | Read Only |
| 0 | --- | No Access |

**Special Bits:**
- **Sticky Bit (1)**: Prevents users from deleting files they don't own (e.g., `1775` = 1775 = 1 + 775)
- **Setuid (4)**: Runs with owner's permissions
- **Setgid (2)**: Runs with group's permissions

## Environment Files

| File | Owner | Group | Permissions |
|------|-------|-------|-------------|
| /opt/kijanikiosk/config/api.env | root | kijanikiosk | 640 |
| /opt/kijanikiosk/config/payments-api.env | root | kijanikiosk | 640 |
| /opt/kijanikiosk/config/logs.env | root | kijanikiosk | 640 |

> **640** = Owner (root) can read/write (6), Group (kijanikiosk) can read (4), Others have no access (0). Environment files contain secrets, so only the owning service account (via group membership) should read them.

## ACLs on /opt/kijanikiosk/shared/logs/

The log directory uses default ACLs to ensure new files inherit correct permissions:
