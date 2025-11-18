# Copilot Instructions for splunk-uf-install

## Project Overview

This repository contains a Bash script for unattended installation and configuration of Splunk Universal Forwarder 9.4.4 on Linux systems. The script is designed to be executed remotely via curl and handles the complete setup including deployment client configuration.

## Purpose

The script automates:
- Downloading and installing the Splunk Universal Forwarder RPM package
- Configuring deployment client settings to connect to a deployment server
- Setting up admin credentials (generating a secure password if not provided)
- Configuring proper file ownership and ACLs for the Splunk user
- Enabling boot-start and starting the service

## Repository Structure

```
.
├── README.md                   # Brief project description
├── LICENSE                     # Project license
├── splunk-uf-install.sh       # Main installation script
└── .github/
    └── copilot-instructions.md # This file
```

## Technology Stack

- **Language**: Bash (shell scripting)
- **Target OS**: Linux (specifically RPM-based distributions like RHEL, CentOS, Rocky Linux)
- **Key Tools Used**:
  - `wget` for downloading the RPM
  - `rpm` for package installation
  - `setfacl` for ACL management
  - Standard Bash utilities

## Coding Standards and Conventions

### Shell Scripting Best Practices

1. **Error Handling**:
   - Use `set -euo pipefail` at the beginning of scripts
   - Exit with non-zero status codes on errors
   - Provide clear error messages to stderr using `>&2`

2. **Variable Naming**:
   - Use UPPER_CASE for environment variables and configuration
   - Use descriptive names (e.g., `SPLUNK_HOME`, `DEPLOY_SERVER_URI`)
   - Quote all variable expansions: `"${VARIABLE}"` not `$VARIABLE`

3. **Code Organization**:
   - Use clear section comments with hash marks: `### Section Name ###`
   - Group related functionality together
   - Keep the script linear and easy to follow

4. **Security Considerations**:
   - Never hardcode credentials - use environment variables
   - Generate secure passwords when needed
   - Validate user input and check prerequisites (e.g., root access)
   - Use proper quoting to prevent injection vulnerabilities

5. **User Experience**:
   - Provide clear output messages about what's happening
   - Show important configuration details at completion
   - Include warnings about storing credentials securely

## Key Configuration Variables

The script uses these configurable environment variables:
- `SPLUNK_USER` - System user for Splunk (default: splunkfwd)
- `SPLUNK_ADMIN_USER` - Splunk admin username (default: admin)
- `SPLUNK_ADMIN_PASS` - Splunk admin password (generated if not provided)
- `DEPLOY_SERVER_URI` - Deployment server address (default: 192.168.4.32:8089)
- `PHONE_HOME_INTERVAL` - Deployment client check-in interval in seconds (default: 600)

## Splunk-Specific Conventions

1. **Directory Structure**:
   - Splunk home: `/opt/splunkforwarder`
   - App configuration: `${SPLUNK_HOME}/etc/apps/`
   - System configuration: `${SPLUNK_HOME}/etc/system/local/`

2. **Configuration Files**:
   - Use `.conf` extension for Splunk configuration files
   - Follow Splunk's INI-style format with `[stanza]` sections
   - Store custom app configs in `local/` directories

3. **Service Management**:
   - Use Splunk's built-in commands for service control
   - Always use `--accept-license --answer-yes --no-prompt` for non-interactive operation

## When Making Changes

1. **Test Changes**: Any modifications should be tested on a clean Linux system
2. **Maintain Idempotency**: The script should be safe to run multiple times
3. **Preserve Backwards Compatibility**: Don't break existing functionality
4. **Update Documentation**: Keep the README.md in sync with script capabilities
5. **Security First**: Never introduce vulnerabilities or expose credentials

## Common Tasks

### Adding a New Configuration Option

1. Add the environment variable with a default value in the "Configurable variables" section
2. Use the variable in the appropriate section
3. Document it in this file and the final output message

### Modifying Splunk Configuration

1. Locate the relevant app directory structure
2. Use heredoc syntax for creating configuration files
3. Ensure proper quoting and variable expansion
4. Set correct ownership after file creation

### Error Handling

1. Check command exit codes for critical operations
2. Provide helpful error messages
3. Use conditional execution (`||`, `&&`) appropriately
4. Exit early on fatal errors
