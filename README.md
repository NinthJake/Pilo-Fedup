Fedup Repo: https://codeberg.org/pmp/dotfiles/src/branch/main/main.toml

# Fedup

Declarative Fedora system manager. All `.toml` files in this directory are
merged together, so you can split your config across multiple files however
you like. Edit them, then run:

```
fedup sync
```

## Settings (main.toml)

### auto_prune

When true, `fedup sync` removes any package that is:

1. Managed by fedup (added via `add` or `migrate`)
2. NOT listed in `packages.toml`'s install array

This gives you a true declarative setup: declare what you want, and fedup
removes the rest. You will be prompted before any removal (use `-y` to skip).
Default: `false`

### enable_rpmfusion

When true, automatically installs RPM Fusion free and nonfree repositories
before syncing dnf packages. This is needed if you install packages from
RPM Fusion (like nvidia drivers, multimedia codecs, etc.).

This is equivalent to adding rpmfusion entries to `repos.toml`, but is a
convenient shortcut. The repos are only installed if not already present.

Default: `false`

### auto_push

When true, commits your files to the repo on `fedup sync`.

## Hooks

Hooks are commands that run before and after modules during `fedup sync`.
They run in order and if one fails, the remaining hooks in that list still run
(errors are reported at the end).

### Hook forms

- String: `"command"` → runs every sync
- Object: `{ cmd = "...", once = true }` → runs once (tracked in state)
- Object: `{ cmd = "...", unless = "test ..." }` → runs only if the test fails

### Common use cases

- Clone dotfiles repo if not present:

  ```toml
  { cmd = "git clone git@github.com:user/dotfiles.git /tmp/dotfiles",
    unless = "test -d /tmp/dotfiles" }
  ```

- Run Neovim plugin sync once after first install:

  ```toml
  { cmd = "nvim --headless '+Lazy! sync' +qa", once = true }
  ```

- Refresh package cache before installing: `"sudo dnf makecache"`

### Per-module hooks

Hooks can be scoped to specific modules by defining them in that module's
config. For example, in `packages.toml`:

```toml
[dnf.hooks]
pre = ["sudo dnf makecache"]
```

Supported per-module hook sections:
`[dnf.hooks]`, `[git.hooks]`, `[dotfiles.hooks]`, `[services.hooks]`

## Repositories (repos.toml)

fedup can enable additional dnf repositories before installing packages.
This is useful for software not in the official Fedora repos.

Note: RPM Fusion is handled by `enable_rpmfusion` in `main.toml` — you don't
need to add it here if you use that setting.

Repo entry fields:

- `name` — A label for the repo (used in output messages)
- `url` — Either a `.repo` file URL or a `.rpm` package URL
- `gpg_key` — Optional GPG key URL to import before adding the repo

URL types:

- `.repo` files → uses: `dnf config-manager addrepo --from-repofile <url>`
- `.rpm` files → uses: `dnf install -y <url>`

## Dotfiles (dotfiles.toml)

fedup creates symlinks from your dotfiles repository to their expected
locations. This lets you keep all dotfiles in one repo while still having
them in the right places.

Each entry has:

- `target` — Where the actual files live (source)
- `link` — Where the symlink should be created (destination)

If a file already exists at the link path and isn't a fedup symlink, fedup
will ask before replacing it. Existing files are backed up to
`~/.local/share/fedup/backups/` before being replaced.

Common dotfile locations:

- `~/.config/nvim` — Neovim config
- `~/.config/kitty` — Kitty terminal config
- `~/.bashrc` — Bash config
- `~/.config/wezterm` — WezTerm config
- `~/.config/gtk-3.0` — GTK settings

## Git repositories (git.toml)

fedup will clone these repositories and keep them updated with `git pull`.

Use cases:

- Clone your dotfiles repo and symlink files into place via `dotfiles.toml`
- Clone Neovim plugin repos or other tool dependencies
- Keep project repos up to date across machines

Repo entry fields:

- `url` — Git remote URL (HTTPS or SSH)
  - SSH example: `git@github.com:user/repo.git`
  - HTTPS example: `https://github.com/user/repo.git`
- `path` — Local directory to clone into (supports `~` expansion)
  - Example: `~/.config/nvim`, `~/projects/myproject`
- `pull` — Whether to run `git pull --ff-only` on every sync (default: `true`)
  - Set to `false` for repos you want to clone once and never update
- `branch` — Optional branch to clone (default: remote default branch)
  - Example: `"main"`, `"develop"`, `"v2.0"`

SSH key setup: if you use SSH URLs and get "Permission denied", generate a key:

```
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
```

Then add `~/.ssh/id_ed25519.pub` to your git hosting service.

SSH config (optional, for custom keys):

```
Host codeberg.org
  IdentityFile ~/.ssh/id_ed25519_codeberg
```

## Services (services.toml)

fedup can enable, disable, or mask systemd services during sync.
It checks the current state first and only acts if a change is needed.

- `enable` — Enable and start the service (`systemctl enable --now`)
- `disable` — Disable and stop the service (`systemctl disable --now`)
- `mask` — Fully mask the service (prevents any activation)

## Hyprland (hyprland.toml)

This file wires up everything for a Hyprland session:

1. `[repos]` — enables the Hyprland COPR (not in Fedora's main repos)
2. `[dnf]` — compositor + ecosystem packages
3. `[dotfiles]` — symlinks the config (Lua, since Hyprland 0.55) into place

The actual Hyprland configuration lives in
`~/.config/fedup/dotfiles/hypr/hyprland.lua`, which is inside this git repo
and backed up by `auto_push`.

After `fedup sync`, log out and pick "Hyprland" in your display manager.
