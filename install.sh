#!/usr/bin/env bash
# ============================================================================
#  install.sh — bootstrap a fresh Mac from this dotfiles repo
#  Usage: ./install.sh
# ============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "→ dotfiles root: $DOTFILES"

# ----------------------------------------------------------------------------
#  1. Homebrew
# ----------------------------------------------------------------------------
if ! command -v brew >/dev/null; then
  echo "→ installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✓ Homebrew already installed"
fi

# ----------------------------------------------------------------------------
#  2. Brew bundle (public packages)
# ----------------------------------------------------------------------------
echo "→ brew bundle"
brew bundle --file "$DOTFILES/Brewfile"

# Work bundle is optional and gitignored. Only runs if the file exists locally.
if [[ "${INSTALL_WORK_BUNDLE:-no}" == "yes" && -f "$DOTFILES/Brewfile.work" ]]; then
  echo "→ brew bundle (work, local-only)"
  brew bundle --file "$DOTFILES/Brewfile.work" || \
    echo "⚠️  work bundle failed — skipping."
fi

# ----------------------------------------------------------------------------
#  3. Oh My Zsh (if not installed)
# ----------------------------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "→ installing Oh My Zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "✓ Oh My Zsh already installed"
fi

# ----------------------------------------------------------------------------
#  4. Symlink home dotfiles
# ----------------------------------------------------------------------------
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local backup="${dst}.predotfiles.$(date +%Y%m%d-%H%M%S)"
    echo "  backing up $dst → $backup"
    mv "$dst" "$backup"
  fi
  ln -s "$src" "$dst"
  echo "  ✓ $dst → $src"
}

echo "→ symlinking home/"
link "$DOTFILES/home/.zshrc"    "$HOME/.zshrc"
link "$DOTFILES/home/.zshenv"   "$HOME/.zshenv"
link "$DOTFILES/home/.zprofile" "$HOME/.zprofile"
link "$DOTFILES/home/.p10k.zsh" "$HOME/.p10k.zsh"

# ----------------------------------------------------------------------------
#  5. Ghostty config
# ----------------------------------------------------------------------------
echo "→ symlinking ghostty config"
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
link "$DOTFILES/config/ghostty/config.ghostty" \
     "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

# ----------------------------------------------------------------------------
#  6. lazygit config
# ----------------------------------------------------------------------------
echo "→ symlinking lazygit config"
mkdir -p "$HOME/.config/lazygit"
link "$DOTFILES/config/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

# ----------------------------------------------------------------------------
#  7. OpenCode config, agents, and custom skills
# ----------------------------------------------------------------------------
echo "→ symlinking opencode config"
mkdir -p "$HOME/.config/opencode"
link "$DOTFILES/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
link "$DOTFILES/opencode/tui.json" "$HOME/.config/opencode/tui.json"
link "$DOTFILES/opencode/oh-my-opencode-slim.json" "$HOME/.config/opencode/oh-my-opencode-slim.json"
link "$DOTFILES/opencode/dcp.jsonc" "$HOME/.config/opencode/dcp.jsonc"

# opencode merges opencode.json and opencode.jsonc (plugin lists are combined).
# The tracked .jsonc is the only main config; warn if an installer left a .json.
if [[ -e "$HOME/.config/opencode/opencode.json" ]]; then
  echo "  ⚠️  ~/.config/opencode/opencode.json exists alongside the tracked opencode.jsonc."
  echo "     Merge anything you need into opencode/opencode.jsonc, then remove opencode.json."
fi

echo "→ symlinking opencode agents"
mkdir -p "$HOME/.config/opencode/agents"
for agent in "$DOTFILES/opencode/agents/"*.md; do
  name="$(basename "$agent")"
  link "$agent" "$HOME/.config/opencode/agents/$name"
done

echo "→ symlinking opencode custom skills"
mkdir -p "$HOME/.config/opencode/skills"
for skill in "$DOTFILES/opencode/skills/"*; do
  [[ -d "$skill" ]] || continue
  name="$(basename "$skill")"
  mkdir -p "$HOME/.config/opencode/skills/$name"
  link "$skill/SKILL.md" "$HOME/.config/opencode/skills/$name/SKILL.md"
done

# ----------------------------------------------------------------------------
#  8. pokemon-colorscripts (used as fastfetch logo in .zshrc)
# ----------------------------------------------------------------------------
if ! command -v pokemon-colorscripts >/dev/null; then
  echo "→ installing pokemon-colorscripts to /opt/homebrew"
  POKE_TMP="$(mktemp -d)"
  git clone --depth=1 https://github.com/acxz/pokescript.git "$POKE_TMP/pokescript"
  POKE_INSTALL_DIR=/opt/homebrew/opt
  POKE_BIN_DIR=/opt/homebrew/bin
  rm -rf "$POKE_INSTALL_DIR/pokemon-colorscripts"
  mkdir -p "$POKE_INSTALL_DIR/pokemon-colorscripts"
  cp -rf "$POKE_TMP/pokescript/colorscripts" "$POKE_INSTALL_DIR/pokemon-colorscripts/"
  cp "$POKE_TMP/pokescript/pokemon-colorscripts.sh" "$POKE_INSTALL_DIR/pokemon-colorscripts/"
  cp "$POKE_TMP/pokescript/nameslist.txt" "$POKE_INSTALL_DIR/pokemon-colorscripts/"
  rm -f "$POKE_BIN_DIR/pokemon-colorscripts"
  ln -s "$POKE_INSTALL_DIR/pokemon-colorscripts/pokemon-colorscripts.sh" "$POKE_BIN_DIR/pokemon-colorscripts"
  rm -rf "$POKE_TMP"
  echo "  ✓ pokemon-colorscripts installed"
else
  echo "✓ pokemon-colorscripts already installed"
fi

# ----------------------------------------------------------------------------
#  9. Done
# ----------------------------------------------------------------------------
cat <<EOF

✅ Bootstrap complete.

Next steps:
  - Restart your shell:                          exec zsh
  - Restart Ghostty to pick up new config.
  - Install third-party OpenCode skills (custom skills are managed here):
      git clone https://github.com/mattpocock/skills /tmp/mpskills
      cp -r /tmp/mpskills/skills/engineering/* ~/.config/opencode/skills/
      # then prune / pick what you want
  - For work-only packages (if you have a local Brewfile.work):
      INSTALL_WORK_BUNDLE=yes $DOTFILES/install.sh

EOF
