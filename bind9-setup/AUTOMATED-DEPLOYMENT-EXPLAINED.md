# Automated Bind9 DNS Deployment - Step-by-Step Breakdown

This guide explains, in very detailed steps, how the `deploy_bind9.sh` script automates the deployment and validation of your Bind9 DNS server. Each step is broken down to show exactly what happens and why, so you can understand, audit, or manually reproduce the process if needed.

---

## 1. Preparation
- **Ensure you have all zone/config files in the repo directory.**
- **Log in to your DNS server with sudo/root privileges.**

## 2. Script Start & Environment Setup
- The script sets strict error handling (`set -e`) so any failure aborts the process.
- It determines the repo directory (`REPO_DIR`) and the BIND config directory (`BIND_DIR=/etc/bind`).

## 3. Service Check
- Checks if the `named.service` (Bind9) is installed and available. If not, it aborts with an error.

## 4. Hostname & IP Detection
- Reads the server's hostname from `/etc/hostname`.
- Sets the DMZ IP (`DMZ_IP=172.16.40.3`) for all tests.
- Detects the server's main IP (prefers the DMZ IP if present).

## 5. Ensure Host A Record
- Checks if the server's hostname has an A record in `db.cybacad.lab`.
- If missing, appends it. If present, updates it to the current IP.

## 6. Backup & Copy Config Files
- Backs up the current `/etc/bind/named.conf.options` if not already backed up.
- Copies the repo's `named.conf.options` and `named.conf.local` to `/etc/bind/`.
- Copies all `db.*` zone files to `/etc/bind/`.
- Removes any old monolithic reverse zone file (`db.192`) from `/etc/bind/`.

## 7. Set Permissions
- Sets ownership of all zone files to `root:bind`.
- Sets permissions to `644` (readable by Bind, not world-writable).

## 8. Validate Configuration
- Runs `named-checkconf` to validate the main config.
- Runs `named-checkzone` for every zone file to check for syntax errors.

## 9. Restart & Enable Bind9
- Restarts the `named` service to apply changes.
- Enables it to start on boot.
- Prints the service status for confirmation.
- Reloads all zones with `rndc reload`.

## 10. Automated DNS Testing
- Defines lists of A and PTR records to test (forward and reverse lookups).
- For each of 127.0.0.1 and 172.16.40.3:
  - Tests all A records using `dig` and checks the returned IP matches the expected value.
  - Tests all PTR records (reverse lookups) and checks the returned hostname matches the expected value.
  - Prints OK or FAIL for each test, with details.
- If any test fails, the script aborts and prints the error.

## 11. Final Output
- Prints a completion message and a reminder to set client DNS to 172.16.40.3 if needed.

---

### What This Automation Guarantees
- All config and zone files are up-to-date and in the right place.
- Permissions are correct for Bind9 to read the files.
- All syntax and logic errors are caught before service reload.
- The DNS server is restarted and enabled.
- Both localhost and DMZ IP interfaces are tested for all records.
- You get immediate feedback if anything is wrong, with clear error messages.

---

**This process replaces dozens of manual steps with a single, repeatable, and auditable script.**

If you want this as a section in your MANUAL-SETUP.md, just copy and paste, or let me know to insert it for you.
