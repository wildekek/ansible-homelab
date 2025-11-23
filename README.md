# Ansible Homelab

This repo contains my homelab Ansible playbooks.

The inventory is based on the proxmox API, which requires the PROXMOX_API_TOKEN env variable to be set.

A helper script that retrieves the token from Bitwarden is included:
> ❯ eval (./unlock-bitwarden-proxmox.sh )
