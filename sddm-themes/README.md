# SDDM themes

Put your login screen theme in a directory here, e.g. `sddm-themes/my-theme/`,
then set `sddm_theme: my-theme` in `group_vars/all.yml` and run:

```sh
./bootstrap.sh --tags sddm
```

The playbook copies the directory to `/usr/share/sddm/themes/my-theme/` and
makes it the current theme. With `sddm_theme: ""`, SDDM uses its built-in theme.

## Minimum layout

```
my-theme/
  metadata.desktop   # required
  Main.qml           # entry point (MainScript)
  theme.conf         # optional settings, readable from QML via `config`
```

`metadata.desktop`:

```ini
[SddmGreeterTheme]
Name=my-theme
Type=sddm-theme
MainScript=Main.qml
ConfigFile=theme.conf
Theme-Id=my-theme
Theme-API=2.0
QtVersion=6
```

`QtVersion=6` is required. Without it SDDM looks for the Qt 5 greeter, which
Arch doesn't ship, and silently falls back to its built-in theme. The
playbook refuses to deploy a theme that's missing it.

## What QML can use

SDDM exposes these to `Main.qml`:

| Name | What it is |
|---|---|
| `sddm` | `login(user, password, sessionIndex)`, `powerOff()`, `reboot()`, `suspend()`, `hibernate()`; `hostName`, `canPowerOff`, `canReboot`, `canSuspend`...; signals `loginSucceeded()`, `loginFailed()` |
| `userModel` | Users (roles `name`, `realName`, `icon`, ...), plus `lastUser` and `lastIndex` |
| `sessionModel` | Sessions (Hyprland), plus `lastIndex` |
| `config` | Values from `theme.conf`: `config.background`, or `config.stringValue("key")`, `boolValue`, `intValue`, `realValue` |
| `keyboard` | Keyboard layout and caps/num lock state |
| `screenModel`, `primaryScreen` | Screen geometry and whether this is the primary screen |

`import SddmComponents 2.0` gives you SDDM's stock widgets (`TextBox`,
`PasswordBox`, `ComboBox`, `Clock`, `Background`, ...) if you want them.

Any Qt module you import beyond QtQuick (e.g. `QtMultimedia`,
`Qt5Compat.GraphicalEffects`) needs its package in `extra_packages`, e.g.
`qt6-multimedia-ffmpeg` or `qt6-5compat`.

## Preview without logging out

```sh
sddm-greeter-qt6 --test-mode --theme sddm-themes/my-theme
```

This opens the theme in a window. Logging in from it doesn't do anything.

## Keep in mind

The greeter is the process that receives your password. Avoid network
requests, `Qt.openUrlExternally`, or anything that writes or logs the
password field. Pass it to `sddm.login()` and nowhere else.
