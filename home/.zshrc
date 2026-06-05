# ============================================================================
#  ~/.zshrc (managed by ~/projects/dotfiles)
#  Layout: env → instant prompt → omz → tools → keys → aliases → prompt theme
# ============================================================================

# ---- Homebrew (MUST be first so $PATH includes /opt/homebrew/bin) ----
eval "$(/opt/homebrew/bin/brew shellenv)"

# ---- Welcome banner (BEFORE instant prompt — any console output must go here) ----
# Only on interactive login shells (skips scripts and subshells).
if [[ -o login && -o interactive ]] && command -v fastfetch >/dev/null; then
  fastfetch
fi

# ---- Powerlevel10k instant prompt config (must be before the block) ----
POWERLEVEL9K_INSTANT_PROMPT=quiet

# ---- Powerlevel10k instant prompt block ----
# Anything BELOW this point must NOT print to the console.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
#  History — bigger, deduped, shared across sessions
# ============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ============================================================================
#  Oh-My-Zsh
# ============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # empty: we use powerlevel10k directly below

plugins=(
  git
  zsh-autosuggestions
  zoxide
)

source $ZSH/oh-my-zsh.sh

# ============================================================================
#  Modern CLI tools
# ============================================================================

# fzf — fuzzy finder (Ctrl+R history, Ctrl+T file picker, Alt+C cd picker)
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
  if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
fi

# ============================================================================
#  Aliases — modern replacements
# ============================================================================
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons'
  alias ll='eza -l --group-directories-first --icons --git'
  alias la='eza -la --group-directories-first --icons --git'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
  alias llt='eza -l --tree --level=2 --icons --group-directories-first --git'
fi
if command -v bat >/dev/null; then
  alias cat='bat --paging=never'
  alias less='bat'
  export BAT_THEME="gruvbox-dark"
fi
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias glg='git log --oneline --graph --decorate --all'

# ============================================================================
#  Editor & language env
# ============================================================================
export EDITOR='nvim'
export VISUAL='nvim'
[ -z "$LANG" ] && export LANG=en_US.UTF-8

# ============================================================================
#  Tool-specific paths
# ============================================================================

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Windsurf (if installed)
[ -d "$HOME/.codeium/windsurf/bin" ] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# git-ai (if installed)
[ -d "$HOME/.git-ai/bin" ] && export PATH="$HOME/.git-ai/bin:$PATH"

# Python pinning (only if 3.11 is on PATH)
if command -v python3.11 >/dev/null; then
  alias python3='python3.11'
  alias pip3='python3.11 -m pip'
fi

# ============================================================================
#  Local-only / work-specific overrides
#  Drop any *.zsh file into ~/projects/dotfiles/work/ and it will be sourced.
#  The work/ dir is gitignored, so contents stay off this public repo.
# ============================================================================
if [ -d "$HOME/projects/dotfiles/work" ]; then
  for _f in "$HOME/projects/dotfiles/work/"*.zsh(N); do
    source "$_f"
  done
  unset _f
fi

# ============================================================================
#  Powerlevel10k theme — load directly (faster than via omz theme system)
# ============================================================================
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================================
#  Syntax highlighting — MUST be sourced last
# ============================================================================
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
