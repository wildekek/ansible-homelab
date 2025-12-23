# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an Ansible homelab configuration repository that manages infrastructure across multiple environments including Proxmox VMs, physical machines, and containerized services.

## Key Commands

### Basic Operations
- `ansible-playbook homelab.yaml` - Run the main homelab playbook
- `ansible-playbook update.yaml` - Update all systems and Docker containers
- `ansible-playbook docker-clean.yaml` - Clean up Docker resources
- `ansible-galaxy install -r requirements.yml` - Install required Ansible collections

### Inventory Management
- `ansible-inventory --list` - View all hosts and groups
- `ansible-inventory --graph` - Show inventory structure
- The repository uses dual inventory sources: `inventory.yaml` (static) and `inventory_proxmox.yaml` (dynamic Proxmox plugin)

### Testing and Validation
- `ansible-playbook --check homelab.yaml` - Dry run of main playbook
- `ansible all -m ping` - Test connectivity to all hosts

## Architecture

### Inventory Structure
- **Static inventory** (`inventory.yaml`): Physical machines and manually defined hosts
- **Dynamic inventory** (`inventory_proxmox.yaml`): Automatically discovers Proxmox VMs/LXCs using the community.proxmox plugin
- **Group variables**: No group_vars directory found; variables are defined within playbooks and roles

### Role-Based Organization
The repository uses a role-based approach where hosts are grouped by function:
- `role_docker` - Hosts running Docker containers
- `role_adguard` - AdGuard Home DNS filtering
- `role_pbs_client` - Proxmox Backup Server clients
- `role_labelprinter` - Label printer management

### Key Roles
- **docker_host**: Installs Docker, creates users/groups, sets up directories
- **adguard**: AdGuard Home configuration
- **proxmox_backup_client**: Proxmox Backup Server client setup
- **labelprinter**: Label printer service management
- **shairport_sync**: AirPlay audio receiver (newest addition)

### Authentication & Security
- SSH key authentication configured (`.ssh/id_ansible`)
- Ansible Vault for secrets (`.vault_pass` file)
- Proxmox API token stored in vault format
- Default remote user: `willem` (overrideable per host)

### Playbook Structure
- **homelab.yaml**: Main deployment playbook with role assignments
- **update.yaml**: System and container updates
- **docker-clean.yaml**: Docker maintenance tasks
- **bootstrap-cloudinit.yaml**: Cloud-init configuration for VM deployment

### Docker Integration
- Docker containers managed via `community.docker.docker_compose_v2`
- Docker files expected in `./docker` directory relative to playbook execution
- Container lifecycle managed through update and cleanup playbooks

## Configuration Notes

- Ansible configuration in `ansible.cfg` sets default inventory files and vault password
- Python interpreter set to `auto_silent` for compatibility
- Repository cache updates are performed but marked as `changed_when: false`
- Host filtering excludes stopped VMs and Windows machines by default

## CI/CD Integration (Semaphore)

### Secret Management Strategy

This repository uses environment variables for Proxmox API tokens, with `unlock-bitwarden-proxmox.sh` script for local development:

#### How It Works
- **`inventory/proxmox.yaml:9`**: `token_secret: "{{ lookup('env', 'PROXMOX_API_TOKEN') }}"`
- **`update.yaml:8`**: `proxmox_api_token: "{{ lookup('env', 'PROXMOX_API_TOKEN') }}"`
- **`unlock-bitwarden-proxmox.sh`**: Script that retrieves the token from Bitwarden and sets `PROXMOX_API_TOKEN` env var (not needed in Semaphore)

#### Local Development
Use the Bitwarden script to retrieve and set the token, then run playbooks:
```bash
eval "$(./unlock-bitwarden-proxmox.sh)"
ansible-playbook update.yaml
```

Or set the variable directly if you have the token:
```bash
export PROXMOX_API_TOKEN="your-token-here"
ansible-playbook update.yaml
```

The script retrieves the token from a Bitwarden item (defaults to "proxmox ansible").

#### Semaphore Configuration
In Semaphore Task Configuration, set this environment variable:

- **`PROXMOX_API_TOKEN`**: Your Proxmox API token

Semaphore will pass the env var to Ansible, which reads it from the environment - no script needed.

### Configuration Details

- **`unlock-bitwarden-proxmox.sh`**: Script that retrieves token from Bitwarden and exports `PROXMOX_API_TOKEN` (tracked in git - contains no secrets)
- **`.gitignore`**: Uses wildcard patterns (`*token*`, `*secret*`) to ignore files that might contain secrets
- **`inventory/proxmox.yaml:9`**: Reads `PROXMOX_API_TOKEN` from environment
- **`update.yaml:8`**: Reads `PROXMOX_API_TOKEN` from environment

### Benefits of This Approach

- **Works everywhere**: Environment variables work identically in local and Semaphore
- **Git-safe**: Script retrieves secrets from Bitwarden at runtime, no secrets in version control
- **No file dependencies in Semaphore**: Only environment variable needed, no scripts
- **Easy rotation**: Update token in Semaphore or Bitwarden vault
- **Clear and transparent**: Token source is explicit in comments

### Troubleshooting

If runs fail with token errors:
1. Verify `PROXMOX_API_TOKEN` is set: `echo $PROXMOX_API_TOKEN`
2. For local: Run `eval "$(./unlock-bitwarden-proxmox.sh)"` first
3. For Semaphore: Check env var is set in task configuration
4. Ensure the token is valid and active in Proxmox