#!/usr/bin/env bash
#
# Splunk Universal Forwarder 9.4.4 unattended install + deployment client config
# Intended for use as:
# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/josephbolus/splunk-uf-install/main/splunk-uf-install.sh)"
#

set -euo pipefail

### Sanity: root check #########################################################

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "This script must be run as root. Try: sudo bash splunk-uf-install.sh" >&2
  exit 1
fi

### Configurable variables #####################################################

SPLUNK_RPM_NAME="splunkforwarder-9.4.4-f627d88b766b.x86_64.rpm"
SPLUNK_RPM_URL="https://download.splunk.com/products/universalforwarder/releases/9.4.4/linux/${SPLUNK_RPM_NAME}"

SPLUNK_HOME="/opt/splunkforwarder"
SPLUNK_USER="${SPLUNK_USER:-splunkfwd}"
SPLUNK_ADMIN_USER="${SPLUNK_ADMIN_USER:-admin}"
DEPLOY_SERVER_URI="${DEPLOY_SERVER_URI:-192.168.4.32:8089}"
PHONE_HOME_INTERVAL="${PHONE_HOME_INTERVAL:-600}"

### Generate admin password if not provided ####################################

GENERATED_PASS=0

if [[ -z "${SPLUNK_ADMIN_PASS:-}" ]]; then
  # Readable-ish: avoid ambiguous characters, use A-H J-N P-Z 2-9
  # Read a fixed block first to avoid SIGPIPE when head closes the pipe
  RAND_SUFFIX="$(dd if=/dev/urandom bs=256 count=1 2>/dev/null | tr -dc 'A-HJ-NP-Z2-9' | head -c 6)"
  SPLUNK_ADMIN_PASS="Splunk${RAND_SUFFIX}"
  GENERATED_PASS=1
fi

echo "Using Splunk admin username: ${SPLUNK_ADMIN_USER}"
if [[ "${GENERATED_PASS}" -eq 1 ]]; then
  echo "Generated Splunk admin password: ${SPLUNK_ADMIN_PASS}"
else
  echo "Using provided SPLUNK_ADMIN_PASS from environment."
fi

### Create Splunk user before RPM installation ###################################

# Create the Splunk user before RPM installation to avoid conflicts
# The RPM will use this user if it already exists
if ! id "${SPLUNK_USER}" >/dev/null 2>&1; then
  echo "Creating ${SPLUNK_USER} user..."
  /usr/sbin/useradd -r -d "${SPLUNK_HOME}" -s /sbin/nologin -c "Splunk Universal Forwarder" "${SPLUNK_USER}"
else
  echo "User ${SPLUNK_USER} already exists."
fi

### Install Splunk UF RPM (if not already installed) ###########################

if ! rpm -q splunkforwarder >/dev/null 2>&1; then
  echo "Downloading Splunk Universal Forwarder RPM..."
  wget -O "${SPLUNK_RPM_NAME}" "${SPLUNK_RPM_URL}"

  chmod +x "${SPLUNK_RPM_NAME}"
  echo "Installing Splunk Universal Forwarder RPM..."
  rpm -i "./${SPLUNK_RPM_NAME}"
else
  echo "splunkforwarder package already installed, skipping RPM install."
fi

### Configure deployment client app ###########################################

DEPLOY_APP_DIR="${SPLUNK_HOME}/etc/apps/doi_blm_deploymentclient/local"
mkdir -p "${DEPLOY_APP_DIR}"

cat <<EOF > "${DEPLOY_APP_DIR}/deploymentclient.conf"
[deployment-client]
phoneHomeIntervalInSecs = ${PHONE_HOME_INTERVAL}

[target-broker:deploymentServer]
targetUri = ${DEPLOY_SERVER_URI}
EOF

echo "Wrote deployment client config to ${DEPLOY_APP_DIR}/deploymentclient.conf"

### Seed admin credentials BEFORE first start ##################################

mkdir -p "${SPLUNK_HOME}/etc/system/local"

cat <<EOF > "${SPLUNK_HOME}/etc/system/local/user-seed.conf"
[user_info]
USERNAME = ${SPLUNK_ADMIN_USER}
PASSWORD = ${SPLUNK_ADMIN_PASS}
EOF

echo "Seeded admin credentials in ${SPLUNK_HOME}/etc/system/local/user-seed.conf"

### Ownership + ACLs ###########################################################

# Ensure Splunk tree owned by Splunk user
chown -R "${SPLUNK_USER}:${SPLUNK_USER}" "${SPLUNK_HOME}"

# Allow Splunk user read/execute on /var/log
if command -v setfacl >/dev/null 2>&1; then
  echo "Setting ACLs on /var/log for user ${SPLUNK_USER}..."
  setfacl -R -m "u:${SPLUNK_USER}:rX" /var/log || true
else
  echo "setfacl not found; skipping ACL setup on /var/log." >&2
fi

### Enable boot-start + start UF non-interactively #############################

SPLUNK_BIN="${SPLUNK_HOME}/bin/splunk"

echo "Enabling boot-start for Splunk UF..."
"${SPLUNK_BIN}" enable boot-start \
  -user "${SPLUNK_USER}" \
  --accept-license \
  --answer-yes \
  --no-prompt

echo "Starting Splunk UF..."
"${SPLUNK_BIN}" start \
  --accept-license \
  --answer-yes \
  --no-prompt

echo "Restarting Splunk UF to ensure config is applied..."
"${SPLUNK_BIN}" restart --answer-yes --no-prompt

echo
echo "===================================================================="
echo " Splunk Universal Forwarder installation completed."
echo " Home: ${SPLUNK_HOME}"
echo " Deployment server: ${DEPLOY_SERVER_URI}"
echo " Phone home interval: ${PHONE_HOME_INTERVAL} seconds"
echo
echo " Admin username: ${SPLUNK_ADMIN_USER}"
echo " Admin password: ${SPLUNK_ADMIN_PASS}"
echo "===================================================================="
echo
echo "Store these credentials securely. The password will not be shown again."
echo
