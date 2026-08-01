# fedup dotfiles

Store your dotfiles here and symlink them into place with `fedup sync`.

## Quick start

1. Clone or copy your dotfiles into this directory:
   ```bash
   git clone git@github.com:user/dotfiles.git ~/.config/fedup/dotfiles/nvim
   ```

2. Add a symlink entry in `~/.config/fedup/dotfiles.toml`:
   ```toml
   [dotfiles]
   symlinks = [
       { target = "~/.config/fedup/dotfiles/nvim", link = "~/.config/nvim" },
   ]
   ```

3. Run `fedup sync` to create the symlinks

## Using hooks for setup

Use pre-hooks in `main.toml` to clone repos before linking:

```toml
[hooks]
pre = [
    { cmd = "git clone git@github.com:user/dotfiles.git /tmp/dotfiles", unless = "test -d /tmp/dotfiles" },
]
```

## Backup

Existing files are backed up to `~/.local/share/fedup/backups/` before being replaced with symlinks.

## Git repo

The entire `~/.config/fedup/` directory is a git repo — commit your changes:

```bash
cd ~/.config/fedup
git add -A
git commit -m "update dotfiles"
```
