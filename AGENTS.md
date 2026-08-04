# Agent Guide: dotfiles

This repository is the source of truth for shell, terminal, and tool configuration on this Mac. **`install.sh` symlinks tracked files into their live locations.** Editing a live file directly can silently drift from the repo, or worse, be overridden by a symlink on the next install.

Read this before writing to any config file under `~` or `~/.config/`.

---

## Symlink map (from `install.sh`)

| Repo path | Live path | Notes |
|---|---|---|
| `home/.zshrc` | `~/.zshrc` | Interactive zsh config |
| `home/.zshenv` | `~/.zshenv` | Env for all zsh invocations |
| `home/.zprofile` | `~/.zprofile` | Login-shell zsh config |
| `home/.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k theme |
| `config/ghostty/config.ghostty` | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` | See Ghostty gotcha below |
| `config/lazygit/config.yml` | `~/.config/lazygit/config.yml` | |
| `opencode/opencode.jsonc` | `~/.config/opencode/opencode.jsonc` | See opencode notes below |
| `opencode/opencode-mem.jsonc` | `~/.config/opencode/opencode-mem.jsonc` | |
| `opencode/oh-my-opencode-slim.json` | `~/.config/opencode/oh-my-opencode-slim.json` | Slim's per-agent model/skill/mcp preset config |
| `opencode/dcp.jsonc` | `~/.config/opencode/dcp.jsonc` | DCP (Dynamic Context Pruning) plugin config |
| `opencode/agents/*.md` | `~/.config/opencode/agents/*.md` | One symlink per agent file |

**Golden rule:** to change a tracked config, edit the file in this repo, not the symlink target. If the symlink target is not a symlink (broken by an installer or ad-hoc edit), re-run `install.sh` to restore.

---

## Ghostty gotcha — config precedence

Ghostty checks config locations in this order:

1. `--config-file` flag
2. `$XDG_CONFIG_HOME/ghostty/config` (usually `~/.config/ghostty/config`)
3. `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS default; **the one this repo symlinks to**)

**If you create `~/.config/ghostty/config`, it silently overrides the tracked config.** This has bitten agents before. Symptoms: config changes committed to `config/ghostty/config.ghostty` appear to do nothing.

Also note the filename oddity: this repo uses `config.ghostty` (not `config`). Ghostty accepts both filenames in the Library path.

**When adding Ghostty config:** edit `config/ghostty/config.ghostty` in this repo. Do **not** create `~/.config/ghostty/config`.

---

## OpenCode configuration — mixed ownership

OpenCode's config directory (`~/.config/opencode/`) is a mix of dotfiles-managed files and files owned by external installers/plugins. **The repo is not the sole source of truth here.**

**Managed by this repo (via `install.sh` symlinks):**
- `opencode.jsonc` — the main config
- `opencode-mem.jsonc`
- `oh-my-opencode-slim.json` — slim's per-agent model/skill/mcp preset config
- `dcp.jsonc` — Dynamic Context Pruning plugin config (@tarquinen/opencode-dcp)
- `agents/*.md` — custom subagent files

**Managed by external tools (not tracked, not symlinked):**
- `opencode.json` — created by `oh-my-opencode-slim`'s installer. If both `.json` and `.jsonc` exist, opencode uses `.jsonc` first. Watch for both files existing when troubleshooting.
- `tui.json` — TUI state (slim writes to this on install)
- `skills/` — a mix of slim-installed skills (managed by slim's manifest at `.oh-my-opencode-slim/skills-manifest.json`) and user-added skills. Don't blindly rm-rf this dir; slim's manifest treats deletion as intentional.
- `.oh-my-opencode-slim/` — slim's internal state
- `node_modules/`, `package.json`, `package-lock.json` — plugin dependencies

**When editing OpenCode config:**
- Changing plugin list, permissions, MCP config, or default agent → edit `opencode/opencode.jsonc` in this repo.
- Changing slim's per-agent models, preset, or council → edit `opencode/oh-my-opencode-slim.json` in this repo (symlinked to `~/.config/opencode/oh-my-opencode-slim.json`).
- Changing DCP settings → edit `opencode/dcp.jsonc` in this repo.
- Adding a new custom agent → drop `.md` in `opencode/agents/` and re-run `install.sh` to symlink it.
- Adding a custom skill → put it in `~/.config/opencode/skills/<name>/` directly. Skills are NOT currently tracked in this repo.

---

## Adding a new tracked config

1. Add the file under `config/<tool>/` or `home/` in this repo.
2. Add a `link` call in `install.sh` in the appropriate section (grep for the `link` function).
3. Run `install.sh` to create the symlink on this machine.
4. Commit both the config and the `install.sh` change.

---

## Adding a new managed OpenCode agent

1. Drop the `.md` in `opencode/agents/` in this repo.
2. The install.sh loop `for agent in "$DOTFILES/opencode/agents/"*.md; do ... link ... done` picks it up automatically. Just re-run `install.sh`.
3. Commit.

---

## What lives outside this repo

- Brew packages → `Brewfile` (public) and `Brewfile.work` (gitignored, work-only)
- Zellij, tmux, other multiplexer configs → not tracked
- Skills for OpenCode → not tracked (see OpenCode section above)
- Local machine state (LSP install decisions, session logs, etc.) → not tracked

---

## Quick checklist for agents editing configs

- [ ] Is the file symlinked via `install.sh`? If yes, edit the repo file, not the symlink target.
- [ ] For Ghostty: don't create `~/.config/ghostty/config`. Edit `config/ghostty/config.ghostty` here.
- [ ] For OpenCode: is the change owned by dotfiles (`opencode.jsonc`, agents) or by an installer (slim's config, DCP)? Route accordingly.
- [ ] Before committing OpenCode changes, sanity-check with `bunx oh-my-opencode-slim@latest doctor`.
- [ ] After committing changes to `install.sh` or new tracked configs, mention that a fresh `install.sh` run is needed to activate on this machine.
