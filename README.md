# splunk-uf-install
Splunk Universal Forwarder 9.4.4 unattended install + deployment client config

## Usage

Run as root on a RHEL-compatible Linux system:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/josephbolus/splunk-uf-install/main/splunk-uf-install.sh)"
```

## Features

- Downloads and installs Splunk Universal Forwarder 9.4.4
- Configures deployment client to connect to a deployment server
- Generates a secure admin password (or uses provided one)
- Sets up proper file ownership and ACLs
- Enables boot-start and starts the service

## Configuration

Environment variables can be set to customize the installation:

- `SPLUNK_USER` - System user for Splunk (default: splunkfwd)
- `SPLUNK_ADMIN_USER` - Splunk admin username (default: admin)
- `SPLUNK_ADMIN_PASS` - Splunk admin password (generated if not provided)
- `DEPLOY_SERVER_URI` - Deployment server address (default: 192.168.4.32:8089)
- `PHONE_HOME_INTERVAL` - Check-in interval in seconds (default: 600)
