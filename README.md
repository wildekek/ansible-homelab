# Ansible Homelab

Ansible configuration for managing a Proxmox-based homelab infrastructure. This repository automates the deployment and maintenance of VMs, LXC containers, and services across multiple hosts.

## Features

### Dynamic Proxmox Inventory
Automatically discovers all VMs and LXC containers from your Proxmox cluster using the `community.proxmox` inventory plugin. No need to manually maintain host lists - just tag your VMs in Proxmox and Ansible picks them up.

### Tag-Based Role Assignment
Proxmox tags translate directly to Ansible groups. Tag a VM with `docker` in Proxmox, and it automatically joins the `role_docker` group in Ansible. This makes role assignment as simple as editing VM tags in the Proxmox UI.

### Pre-Update Snapshots
Before updating any Proxmox VM or container, the update playbook automatically creates a snapshot with configurable retention. If an update breaks something, you can roll back instantly.

### Multi-OS Support
Roles support both Debian and Alpine Linux, with automatic detection and OS-specific handling (package managers, init systems, privilege escalation).

### Bitwarden Integration
Includes a helper script to retrieve the Proxmox API token from Bitwarden, keeping secrets out of the repository while making local development convenient.

### CI/CD Ready
Designed for use with Semaphore or other CI/CD tools. Secrets are managed via environment variables, with a Bitwarden helper script for local development.

## Quick Start

### Prerequisites
- Ansible 2.17+
- A Proxmox VE cluster with API access
- SSH key authentication configured

### Installation

```bash
# Clone the repository
git clone https://github.com/youruser/ansible-homelab.git
cd ansible-homelab

# Install required collections
ansible-galaxy install -r requirements.yml

# Set up your Proxmox API token
export PROXMOX_API_TOKEN="your-token-here"

# Test connectivity
ansible all -m ping
```

### Running Playbooks

```bash
# Deploy all roles to tagged hosts
ansible-playbook homelab.yaml

# Update all systems and containers (with automatic pre-update snapshots)
ansible-playbook update.yaml

# Clean up Docker resources
ansible-playbook docker-clean.yaml

# Bootstrap a fresh cloud-init VM
ansible-playbook bootstrap-cloudinit.yaml
```

## Playbooks

| Playbook | Description |
|----------|-------------|
| `homelab.yaml` | Main deployment playbook - applies roles based on Proxmox tags |
| `update.yaml` | Updates system packages and Docker containers with pre-update snapshots |
| `bootstrap-cloudinit.yaml` | Provisions fresh cloud-init VMs with users, SSH keys, and base packages |
| `docker-clean.yaml` | Cleans up unused Docker resources |

## Roles

| Role | Description |
|------|-------------|
| `docker_host` | Installs Docker, creates users/groups, sets up directories |
| `adguard` | Deploys AdGuard Home DNS filtering via Docker Compose |
| `proxmox_backup_client` | Installs PBS client with systemd timer for scheduled backups |
| `labelprinter` | Label printer service management |

## Inventory Structure

### Dynamic Inventory (Proxmox)
The `inventory/proxmox.yaml` file configures automatic discovery from your Proxmox cluster:
- VMs/containers are grouped by status (`status_running`, `status_stopped`)
- VMs/containers are grouped by type (`type_qemu`, `type_lxc`)
- VMs/containers are grouped by node (`node_proxmox1`)
- **Tags become role groups** (`role_docker`, `role_adguard`, etc.)

### Static Inventory
The `inventory/inventory.yaml` file defines:
- Physical machines not managed by Proxmox
- Host-specific variable overrides
- Special host groups (e.g., `proxmox_hosts` for Proxmox hypervisors)

## Configuration

### Proxmox API Token
The Proxmox API token is read from the `PROXMOX_API_TOKEN` environment variable:

```bash
# Option 1: Use the Bitwarden helper script (retrieves token from Bitwarden vault)
eval "$(./unlock-bitwarden-proxmox.sh)"

# Option 2: Set directly
export PROXMOX_API_TOKEN="your-token-here"
```

### Customizing for Your Environment
1. Update `inventory/proxmox.yaml` with your Proxmox URL and credentials
2. Update `ansible.cfg` with your SSH key path and default user
3. Tag your VMs in Proxmox with the roles you want applied

## Tag Mapping Examples

| Proxmox Tag | Ansible Group | Role Applied |
|-------------|---------------|--------------|
| `docker` | `role_docker` | `docker_host` |
| `adguard` | `role_adguard` | `adguard` |
| `pbs_client` | `role_pbs_client` | `proxmox_backup_client` |
| `homeassistant` | `role_homeassistant` | (excluded from updates) |

## Update Behavior

The `update.yaml` playbook has special handling for different host types:

- **Proxmox hypervisors** (`proxmox_hosts` group): Uses `apt dist-upgrade` for kernel updates
- **Regular Debian hosts**: Uses `apt full-upgrade`
- **Alpine hosts**: Uses `apk upgrade`
- **Docker hosts**: Pulls latest images and recreates containers
- **VMs/containers**: Get automatic pre-update snapshots with 3-snapshot retention

## Requirements

See `requirements.yml` for required Ansible collections:
- `community.general`
- `community.docker`
- `community.proxmox`
- `ansible.posix`

## License

MIT
