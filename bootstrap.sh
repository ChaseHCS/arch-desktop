#!/usr/bin/env bash
# Install Ansible (if needed) and apply the playbook to this machine.
# Usage: ./bootstrap.sh [extra ansible-playbook args, e.g. --tags hyprland]
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root; it uses sudo where needed." >&2
  exit 1
fi

cd "$(dirname "$(readlink -f "$0")")"

# Upgrade before Ansible starts. Doing it inside the play could replace
# Python or Ansible under the running playbook.
sudo pacman -Syu --needed ansible git

exec ansible-playbook site.yml "$@"
