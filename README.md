# dotfiles

Personal dotfiles for macOS. Symlink-based: the repo holds the source of truth; `install.sh` symlinks files into place and runs `brew bundle`.

## Bootstrap a new machine

```bash
git clone git@github.com:RoderickOxen/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
./install.sh
```

Optional work-only packages (kept out of this repo via `.gitignore`):

```bash
INSTALL_WORK_BUNDLE=yes ./install.sh   # only if Brewfile.work exists locally
```

## Layout

```
dotfiles/
├── Brewfile                # brew/cask/font packages
├── install.sh              # bootstrap script
├── home/                   # files that live in $HOME
│   ├── .zshrc
│   ├── .zshenv
│   ├── .zprofile
│   └── .p10k.zsh
├── config/
│   ├── ghostty/
│   │   └── config.ghostty  # symlinked to ~/Library/Application Support/com.mitchellh.ghostty/
│   └── lazygit/
│       └── config.yml      # symlinked to ~/.config/lazygit/
└── opencode/
    └── agents/             # symlinked to ~/.config/opencode/agents/
```

## What's NOT in here

Deliberately excluded:

- **Secrets** — `.ssh/`, `.aws/`, API tokens, history files
- **OpenCode skills** — these come from [`mattpocock/skills`](https://github.com/mattpocock/skills). Bootstrap them separately with the snippet in `install.sh`'s exit message
- **`.gitconfig`** — work email vs personal email; managed per-machine

## Updating

The repo IS your config. Edit files in `~/projects/dotfiles/`; symlinks reflect the change immediately. Commit and push when you want it on other machines.

```bash
cd ~/projects/dotfiles
git status
git add -A && git commit -m "tweak: …" && git push
```

On the other machine:

```bash
cd ~/projects/dotfiles && git pull && exec zsh
```
