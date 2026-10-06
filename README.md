# arch-desktop

Ansible playbook that turns a fresh Arch Linux install into a coding desktop:

- **Desktop:** Hyprland only (no Plasma), with a Lua config (Hyprland ≥ 0.55), waybar, fuzzel, mako, hyprlock, hypridle, hyprpolkitagent, cliphist, grim/slurp
- **Login screen:** SDDM, ready for your own theme in [`sddm-themes/`](sddm-themes/README.md) (built-in theme until you set one)
- **Apps and theming:** Dolphin, Okular, Ark, Gwenview; Breeze Dark across Qt, KDE and GTK apps; KDE file dialogs; GNOME Keyring unlocked at login
- **Shell:** zsh + Oh My Zsh (`robbyrussell`), autosuggestions, syntax highlighting
- **Terminal:** Terminator (with a `tmux` profile) and tmux, Tokyo Night colours throughout
- **Editor:** Neovim with LazyVim (Python, TypeScript, Docker, Ansible, YAML, JSON, TOML, Markdown extras)
- **Peripherals:** Logitech G mice without G HUB: Piper for DPI, buttons, lighting and onboard profiles; Solaar for receivers and battery
- **Music:** Spotify's official client (via `spotify-launcher`, native Wayland) and `spotify-player` in the terminal; both work with the media keys
- **Toolchains:** Python (uv, pipx), Node.js (system + fnm with the current LTS), Docker (compose, buildx)
- **GPU:** NVIDIA open kernel modules with early KMS and suspend/resume support (AMD/Intel also supported)
- **Base:** paru, PipeWire, NetworkManager, microcode, Firefox, Chromium, Nerd Font, maintenance timers
- **Firewall:** nftables, default-deny for incoming connections
- **Hardening:** sysctl hardening, rare network protocols blocked, sshd off (hardened config in place), persistent faillock (lock screen included), `su` limited to wheel

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
./bootstrap.sh          # upgrades the system and installs ansible first, then runs the playbook
sudo reboot
```

Log in at the SDDM screen and you're in Hyprland.

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
| `sddm_theme` | `""` | Your theme's directory name under `sddm-themes/`. See [its README](sddm-themes/README.md) |
| `browsers` | firefox, chromium | |
| `hypr_monitors` | auto | One entry per monitor; see the comment in the file |
| `hypr_kb_layout` | `us` | |
| `omz_plugins`, `zsh_theme` | | |
| `lazyvim_extras` | | Only applied on the first install (`lazyvim.json`). Change later with `:LazyExtras` |
| `enable_python` / `enable_nodejs` / `enable_docker` | `true` | |
| `docker_user_in_group` | `true` | See security notes |
| `enable_logitech` | `true` | Piper, libratbag and Solaar for Logitech G mice; see [Logitech mouse](#logitech-mouse) |
| `logitech_solaar_tray` | `false` | Keep Solaar in the tray for battery status (read the caveat first) |
| `enable_spotify` | `true` | Official Spotify client and spotify-player |
| `spotify_client_id` | `""` | Your own Spotify app's client ID for spotify-player; see [Spotify](#spotify) |
| `enable_firewall` | `true` | nftables, default-deny incoming |
| `firewall_allowed_tcp_ports` / `firewall_allowed_udp_ports` | `[]` | Ports to open; sshd's opens automatically when `sshd_enabled` |
| `firewall_trust_docker_bridges` | `true` | Let containers reach services on the host |
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

Without Plasma there's no System Settings app. Qt/KDE apps take their theme from `~/.config/kdeglobals` and GTK apps from GSettings (change with `gsettings set org.gnome.desktop.interface ...`). Monitors are set in `hyprland.lua` (`hyprctl monitors all` lists them), Wi-Fi through the nm-applet tray icon, and audio through `pavucontrol`.

## Logitech mouse

G HUB doesn't exist for Linux. These cover what it does for G-series mice:

- **Piper** (in fuzzel): DPI stages, button mapping and macros, lighting, report rate and profiles. It writes them to the mouse's onboard memory, so they stick without anything running, even on other computers. Run `ratbagctl list` to check your mouse is detected. libratbag supports most G mice; if yours isn't listed, its model is needed for a workaround.
- **Solaar:** pair the mouse with a Lightspeed/Unifying/Bolt receiver and check the battery. Basic movement and clicks work without either tool.
- **Use Piper for settings and Solaar only for pairing and battery.** Solaar re-applies the settings it remembers whenever the device reconnects, so leaving it running can undo Piper changes. That's why it isn't autostarted. If you want its battery icon in the tray, set `logitech_solaar_tray: true` and mark DPI, report rate and onboard profiles as ignored in Solaar first.

## Spotify

Both clients need Premium (you have it) and show up as Spotify Connect devices, so you can hand playback between them, your phone and speakers. Media keys and `playerctl` control whichever one is playing.

- **Official client:** launch "Spotify (Launcher)" from fuzzel. The first launch downloads Spotify into `~/.local/share/spotify-launcher`; later launches update it. Lossless is off by default: turn it on under Settings → Audio quality.
- **spotify-player:** run `spotify_player` in a terminal or tmux. The first run opens your browser twice to approve access: once for the Web API and once for audio streaming.
- **Own client ID (recommended for spotify-player):** by default spotify-player uses ncspot's client ID, which many users share and which can return `429 Too Many Requests`. Create an app at <https://developer.spotify.com/dashboard> with redirect URI `http://127.0.0.1:8989/login`, put its client ID in `spotify_client_id`, re-run `./bootstrap.sh --tags music`, then run `spotify_player authenticate`. Since 2026, apps in development mode need a Premium owner and allow up to 5 users, which is fine for personal use.

## Security notes

Trade-offs worth knowing about:

- **Login screen theme:** theme QML runs inside the greeter that receives your password, so keep network and process calls out of it.
- **Mouse configuration:** ratbagd, the daemon behind Piper, can write macros into the mouse's onboard memory, and libratbag's default D-Bus policy lets every local account call it. A policy override in `/etc/dbus-1/system.d/ratbagd-restrict.conf` limits it to your user (and root).
- **Spotify:** the official client is closed-source and runs as your user. spotify-launcher checks Spotify's download against the signing key shipped in the Arch package. spotify-player streams through librespot, an unofficial reimplementation of Spotify's protocol, which technically goes against Spotify's terms and can break when Spotify changes things. Its login tokens in `~/.cache/spotify-player/` give access to your account, so treat them like a password.
- **Docker group:** being in `docker` is root-equivalent. Set `docker_user_in_group: false` if you'd rather use `sudo docker` or rootless Docker.
- **AUR:** paru is bootstrapped from the `paru-bin` PKGBUILD, a prebuilt release binary pinned by checksum. AUR packages are user-submitted, so read PKGBUILDs before adding anything to `aur_packages`.
- **Temporary sudoers rule:** while installing `aur_packages`, a `NOPASSWD: /usr/bin/pacman` rule for your user is written to `/etc/sudoers.d/99-ansible-aur`. It's removed in an `always:` block even if the install fails, and it's never written when `aur_packages` is empty. If a run is interrupted (Ctrl-C, crash, power loss) the `always:` block can't run, so every run also deletes a leftover rule as its first step; until then, run `sudo rm /etc/sudoers.d/99-ansible-aur`.
- **ptrace:** `kernel.yama.ptrace_scope = 1`. `gdb ./prog` works, but attaching to a running process (`gdb -p`, `strace -p`) needs sudo.
- **Reverse-path filtering:** `rp_filter` is strict (1) on every interface, including ones created later. If a policy-routing VPN breaks, set it to 2 in `roles/hardening/defaults/main.yml`.
- **faillock:** 5 failed logins in 15 minutes lock the account for 10 minutes. This applies to the login screen, sudo and hyprlock, and the lock survives a reboot. Clear it with `faillock --user <you> --reset`.
- **`su`:** `su` and `su -` are limited to `wheel` members.
- **Firewall:** incoming connections are dropped except replies, ping and IPv6 neighbour discovery, traffic from Docker containers (`firewall_trust_docker_bridges`), and ports you list. Ports Docker publishes with `-p` bypass it, because Docker routes them itself, so bind them to localhost (`-p 127.0.0.1:8080:80`) unless they're meant for the network. Check what's dropped with `sudo nft list table inet arch_desktop`.
- **Not covered** (out of scope, or best done at install time): disk encryption, Secure Boot, kernel command-line hardening (`lockdown=`, `init_on_alloc=`, ...), and locking the root password.

## Layout

```
site.yml             main play: pre-checks, roles, handlers
group_vars/all.yml   the settings you're most likely to change
sddm-themes/         your SDDM theme(s), deployed by the sddm role
roles/
  base/       pacman tuning, full upgrade, base packages, microcode, services
  aur/        paru bootstrap and AUR packages
  gpu/        NVIDIA driver and early KMS, or Mesa for AMD/Intel
  desktop/    PipeWire, fonts, KDE apps, Breeze Dark theming, keyring, browsers
  sddm/       SDDM, your login screen theme, keyring unlock at login
  hyprland/   Hyprland and companion configs
  shell/      zsh and Oh My Zsh
  terminal/   Terminator and tmux
  neovim/     Neovim and LazyVim
  dev/        Python, Node.js (fnm), Docker
  peripherals/ Logitech mouse tools (Piper, libratbag, Solaar)
  music/      Spotify official client and spotify-player
  firewall/   nftables default-deny inbound
  hardening/  sysctl, module blacklist, sshd, faillock, su
```
