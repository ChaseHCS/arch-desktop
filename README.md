# arch-desktop

Ansible playbook that turns a fresh Arch Linux install into a coding desktop:

- **Desktops:** KDE Plasma (Wayland) and Hyprland side by side, chosen at the login screen (Plasma Login Manager, or SDDM if you prefer)
- **Hyprland:** Lua config (Hyprland ≥ 0.55), waybar, fuzzel, mako, hyprlock, hypridle, hyprpolkitagent, cliphist, grim/slurp; KDE portal for file dialogs
- **Shell:** zsh + Oh My Zsh (`robbyrussell`), autosuggestions, syntax highlighting
- **Terminal:** Terminator (with a `tmux` profile) and tmux, Tokyo Night colours throughout
- **Editor:** Neovim with LazyVim (Python, TypeScript, Docker, Ansible, YAML, JSON, TOML, Markdown extras)
- **Toolchains:** Python (uv, pipx), Node.js (system + fnm with the current LTS), Docker (compose, buildx)
- **GPU:** NVIDIA open kernel modules with early KMS and suspend/resume support (AMD/Intel also supported)
- **Base:** paru, PipeWire, NetworkManager, microcode, Firefox, Chromium, Nerd Font, maintenance timers
- **Hardening:** sysctl hardening, rare network protocols blocked, sshd off (hardened config in place), persistent faillock, `su` limited to wheel

## Before you run it

Do a base install first. `archinstall` with the **Minimal** profile works:

- a regular user with sudo (in `wheel`)
- networking via **NetworkManager**
- a bootloader, and mkinitcpio for the initramfs (the archinstall default)
- **NVIDIA:** Turing (RTX 20 / GTX 16) or newer. Arch's driver no longer supports Pascal (GTX 10) and older cards, which need the AUR `nvidia-580xx-*` packages; this playbook doesn't handle those.

## Run

As your normal user (not root):

```sh
git clone https://github.com/chasehcs/arch-desktop.git
cd arch-desktop
./bootstrap.sh          # installs ansible if needed, asks for your sudo password once
sudo reboot
```

At the login screen, choose **Hyprland** or **Plasma (Wayland)** from the session menu.

Re-running is safe; tasks are idempotent. Run part of the playbook with tags:

```sh
./bootstrap.sh --tags hyprland,terminal
./bootstrap.sh --list-tags
./bootstrap.sh --check --diff      # preview changes on an already-provisioned machine
```

## Configuration

Set your options in [`group_vars/all.yml`](group_vars/all.yml), or override them per run with `-e`:

| Variable | Default | Notes |
|---|---|---|
| `gpu_vendor` | `nvidia` | `nvidia`, `amd`, `intel`, `none` |
| `dotfiles_overwrite` | `false` | Dotfiles are only written when missing. Set to `true` to re-render them (a backup is kept). |
| `extra_packages` / `aur_packages` | `[]` | Extra packages from the official repos / the AUR (installed via paru) |
| `display_manager` | `plasmalogin` | KDE's Plasma Login Manager (the Plasma default since 6.6), or `sddm` |
| `browsers` | firefox, chromium | |
| `hypr_monitors` | auto | One entry per monitor; see the comment in the file |
| `hypr_kb_layout` | `us` | |
| `omz_plugins`, `zsh_theme` | | |
| `lazyvim_extras` | | Only applied on the first install (`lazyvim.json`). Change later with `:LazyExtras` |
| `enable_python` / `enable_nodejs` / `enable_docker` | `true` | |
| `docker_user_in_group` | `true` | See security notes |
| `enable_hardening`, `sshd_enabled` | `true`, `false` | Sysctl and faillock values are in `roles/hardening/defaults/main.yml` |

## Hyprland keybindings

| Keys | Action |
|---|---|
| `Super + Return` | Terminator |
| `Super + D` | App launcher (fuzzel) |
| `Super + E` / `Super + B` | Dolphin / browser |
| `Super + Q` | Close window |
| `Super + F` / `Super + V` | Fullscreen / toggle floating |
| `Super + T` / `Super + P` | Toggle split / pseudo-tile |
| `Super + H J K L` or arrows | Move focus |
| `Super + Shift + H J K L` or arrows | Move window |
| `Super + 1…0` / `Super + Shift + 1…0` | Go to workspace / send window to workspace |
| `Super + S` / `Super + Shift + S` | Scratchpad / send window to scratchpad |
| `Super + C` | Clipboard history |
| `Print` / `Shift + Print` | Copy a region to the clipboard / save the full screen to `~/Pictures/Screenshots` |
| `Super + Escape` | Lock |
| `Super + Shift + E` | Exit Hyprland |
| `Super + LMB / RMB drag` | Move / resize window |

The config is in `~/.config/hypr/hyprland.lua`. Idle behaviour (lock after 10 min, screens off after 15) is in `hypridle.conf`.

## Security notes

Trade-offs worth knowing about:

- **Docker group:** being in `docker` is root-equivalent. Set `docker_user_in_group: false` if you'd rather use `sudo docker` or rootless Docker.
- **AUR:** paru is bootstrapped from the `paru-bin` PKGBUILD, a prebuilt release binary pinned by checksum. AUR packages are user-submitted, so read PKGBUILDs before adding anything to `aur_packages`.
- **Temporary sudoers rule:** while installing `aur_packages`, a `NOPASSWD: /usr/bin/pacman` rule for your user is written to `/etc/sudoers.d/99-ansible-aur`. It's removed in an `always:` block even if the install fails, and it's never written when `aur_packages` is empty.
- **ptrace:** `kernel.yama.ptrace_scope = 1`. `gdb ./prog` works, but attaching to a running process (`gdb -p`, `strace -p`) needs sudo.
- **Reverse-path filtering:** `rp_filter` is strict (1). If a policy-routing VPN breaks, set it to 2 in `roles/hardening/defaults/main.yml`.
- **faillock:** 5 failed logins in 15 minutes lock the account for 10 minutes. This applies to the login screen, sudo and hyprlock, and the lock survives a reboot. Clear it with `faillock --user <you> --reset`.
- **`su`:** limited to `wheel` members.
- **Not covered** (out of scope, or best done at install time): a firewall, disk encryption, Secure Boot, kernel command-line hardening (`lockdown=`, `init_on_alloc=`, ...), and locking the root password.

## Layout

```
site.yml             main play: pre-checks, roles, handlers
group_vars/all.yml   the settings you're most likely to change
roles/
  base/       pacman tuning, full upgrade, base packages, microcode, services
  aur/        paru bootstrap and AUR packages
  gpu/        NVIDIA driver and early KMS, or Mesa for AMD/Intel
  desktop/    PipeWire, fonts, Plasma, login manager, browsers
  hyprland/   Hyprland and companion configs
  shell/      zsh and Oh My Zsh
  terminal/   Terminator and tmux
  neovim/     Neovim and LazyVim
  dev/        Python, Node.js (fnm), Docker
  hardening/  sysctl, module blacklist, sshd, faillock, su
```
