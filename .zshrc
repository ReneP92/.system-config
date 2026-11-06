

# -------------------------------------- Powerlevel 10k --------------------------------------------
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
# ---------------------------------------------------------------------------------------------------


# ----------------------------------------- zhistory ------------------------------------------------
# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
FUNCNEST=1000
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify
# ---------------------------------------------------------------------------------------------------


# ---------------------------------------- completion -----------------------------------------------
# macOS's /bin/zsh doesn't search Homebrew's completions (git, gh, brew, ...)
# on its own. compinit has to run before anything below calls compdef (the
# `theme` completion, bun).
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit
# ---------------------------------------------------------------------------------------------------


source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# ---------------------------------------------------------------------------------------------------

# -------------------------------------- Eza (better ls) --------------------------------------------
alias ls="eza --color=always --git --no-filesize --icons=always --no-time --no-user --no-permissions"
# ---------------------------------------------------------------------------------------------------


# ------------------------------------ Zoxide (better cd) -------------------------------------------
eval "$(zoxide init zsh)"
alias cd="z"
# ---------------------------------------------------------------------------------------------------


# ------------------------------------- Bat (better cat) --------------------------------------------
alias cat="bat --theme=ansi"
# -------------------------------------------------------------------------------------------------t-


# ------------------------------------ FZF (Fuzzy Finder) -------------------------------------------
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"
# --------------------------------------------------------------------------------------------------- 


# ------------------------------------ FD (FZF extension) -------------------------------------------
# -- Use fd instead of fzf --
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}
# --------------------------------------------------------------------------------------------------- 



# ---------------------------------- FZF-GIT (FZF extension) ----------------------------------------
source ~/fzf-git.sh/fzf-git.sh
# --------------------------------------------------------------------------------------------------- 


# --- setup fzf theme ---
# Follows the system-wide theme selected with the `theme` command (see
# .scripts/theme); new shells pick up a switch. The colors come from the
# active palette (themes/<name>.conf in the repo). With a translucent theme
# the background is -1 (the terminal default), so wezterm's window shows
# through; `theme background solid` uses the theme's own background.
if [ -r ~/.config/theme/palette.conf ]; then
  source ~/.config/theme/palette.conf
  [ "$(command cat ~/.config/theme/background 2>/dev/null)" = solid ] || THEME_FZF_BG=-1
  export FZF_DEFAULT_OPTS="--color=bg:${THEME_FZF_BG},gutter:${THEME_FZF_BG},${THEME_FZF_COLORS}"
  unset -m 'THEME_*'
fi

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# --------------------------------------------------------------------------------------------------- 


# ---------------------------------------- git-delta ------------------------------------------------


# ------------------------------------------ Others -------------------------------------------------
# Keep only the first copy of each PATH entry: shells started inside tmux (or
# from another shell) inherit a PATH that already holds everything added here.
# Both spellings need the flag: the exports below assign the PATH string.
typeset -U path PATH
export PATH="$PATH:$(go env GOPATH)/bin"
export PATH="$PATH:$HOME/.scripts" # theme switcher etc. (linked from .system-config)

# completion for the `theme` command: subcommands, theme names and flags
_theme() {
  local -a subcommands
  subcommands=(
    'pick:choose a theme interactively with a live preview'
    'set:switch to a theme'
    'background:switch between translucent and solid backgrounds'
    'current:print the current theme'
    'list:list the available themes'
    'preview:render the preview of a theme'
    'help:show usage'
  )
  if (( CURRENT == 2 )); then
    _describe -t commands 'theme command' subcommands
    _values 'theme' ${(f)"$(theme list --names 2>/dev/null)"}
    return
  fi
  case "${words[2]}" in
    set)
      if (( CURRENT == 3 )); then
        _values 'theme' ${(f)"$(theme list --names 2>/dev/null)"}
      elif (( CURRENT == 4 )); then
        _values 'background' --translucent --solid
      fi
      ;;
    preview) (( CURRENT == 3 )) && _values 'theme' ${(f)"$(theme list --names 2>/dev/null)"} ;;
    background) (( CURRENT == 3 )) && _values 'background' translucent solid toggle ;;
    list) (( CURRENT == 3 )) && _values 'option' --names ;;
  esac
}
(( $+functions[compdef] )) && compdef _theme theme


# ---------------------------------------- claude code ----------------------------------------------
alias cc="claude code"
# Claude Code clamps to 256 colors inside tmux unless told otherwise; tmux
# passes truecolor through (RGB in .tmux.conf), so the custom theme's exact
# hex colors render instead of 256-color approximations
export CLAUDE_CODE_TMUX_TRUECOLOR=1

# ---------------------------------------- cursor agent ---------------------------------------------
# Cursor's CLI runs on a bundled node, and the process name is all tmux can
# see, so its tab would read "node". Name the pane for the tab title while it
# runs (@agent_name, see .tmux/statusbar.conf); `always` clears it however
# the CLI exits.
_cursor_agent() {
  [[ -n $TMUX_PANE ]] || { command "$@"; return }
  tmux set-option -p -t "$TMUX_PANE" @agent_name cursor
  { command "$@" } always { tmux set-option -p -t "$TMUX_PANE" -u @agent_name }
}
agent() { _cursor_agent agent "$@" }
cursor-agent() { _cursor_agent cursor-agent "$@" }
alias ca="agent"

# ------------------------------------------ opencode ------------------------------------------------
alias oc="opencode"

# bun completions
[ -s "/Users/renepersau/.bun/_bun" ] && source "/Users/renepersau/.bun/_bun"
export PATH="$HOME/.local/bin:$PATH"
