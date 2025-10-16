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

This repository supports dual secret management to work both locally (with Vault encryption) and in CI/CD environments (with environment variables):

#### Local Development
- Secrets are encrypted using Ansible Vault (`ansible.cfg` → `.vault_pass`)
- The `.vault_pass` file is git-ignored (in `.gitignore`)
- Playbooks reference vault-encrypted variables as defaults

#### Semaphore Configuration
Instead of storing the vault password in Semaphore, use environment variable override:

1. **In Semaphore Project Settings**, add a Secret:
   - **Name**: `PROXMOX_API_TOKEN`
   - **Value**: Your actual Proxmox API token (the decrypted value)

2. **In Semaphore Task Configuration**, set environment variables:
   ```
   PROXMOX_API_TOKEN: Use secret 'PROXMOX_API_TOKEN'
   ```

3. **How it works**:
   - `inventory/proxmox.yaml:9` - Uses vault-encrypted token (local development only)
   - `update.yaml:8` - Uses Jinja2 lookup with fallback: `proxmox_api_token: "{{ lookup('env', 'PROXMOX_API_TOKEN') | default(vault_proxmox_api_token, true) }}"`
   - When `PROXMOX_API_TOKEN` environment variable is set (Semaphore), it takes precedence
   - When not set (local development), vault decryption is used as fallback
   - **For inventory discovery**: The Proxmox dynamic inventory plugin will use the vault token locally or can be overridden via environment variable in Semaphore (see Semaphore documentation on how to set env vars for plugins)

### Benefits of This Approach

- **No vault password sharing**: Semaphore never needs the `.vault_pass` file
- **No duplicate encryption**: Use Vault locally, native secrets in CI/CD
- **Clean separation**: Local and CI/CD secrets managed independently
- **Easier rotation**: Change secrets in Semaphore without re-encrypting files
- **Security**: Each environment has its own isolated secret storage

### Troubleshooting

If Semaphore runs fail with "api_token_secret" errors:
1. Verify `PROXMOX_API_TOKEN` secret is set in Semaphore
2. Ensure the secret value is the raw token (not vault-encrypted)
3. Check environment variables are properly exported in task configuration
4. Run with `ansible-playbook --check` locally to verify playbook syntax