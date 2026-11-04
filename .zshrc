

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
# .scripts/theme); new shells pick up a switch. With a translucent theme the
# background is -1 (the terminal default), so wezterm's window shows through;
# `theme <name> opaque` uses the theme's solid background instead.
case "$(cat ~/.config/theme/current 2>/dev/null)" in
  nightowl)
    _fzf_bg="#011628"
    _fzf_colors="fg:#CBE0F0,hl:#B388FF,fg+:#CBE0F0,bg+:#143652,hl+:#B388FF,info:#06BCE4,prompt:#2CF9ED,pointer:#2CF9ED,marker:#2CF9ED,spinner:#2CF9ED,header:#2CF9ED"
    ;;
  tokyonight)
    _fzf_bg="#1a1b26"
    _fzf_colors="fg:#c0caf5,hl:#2ac3de,fg+:#c0caf5,bg+:#283457,hl+:#2ac3de,info:#545c7e,prompt:#2ac3de,pointer:#ff007c,marker:#ff007c,spinner:#ff007c,header:#ff9e64"
    ;;
  *) # rose-pine (moon), the default
    _fzf_bg="#1f1d2e"
    _fzf_colors="fg:#908caa,hl:#ea9a97,fg+:#e0def4,bg+:#393552,hl+:#ea9a97,info:#9ccfd8,prompt:#908caa,pointer:#c4a7e7,marker:#eb6f92,spinner:#f6c177,header:#3e8fb0"
    ;;
esac
[ "$(cat ~/.config/theme/background 2>/dev/null)" = opaque ] || _fzf_bg=-1
export FZF_DEFAULT_OPTS="--color=bg:${_fzf_bg},gutter:${_fzf_bg},${_fzf_colors}"
unset _fzf_bg _fzf_colors

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
export PATH="$PATH:$(go env GOPATH)/bin"
export PATH="$PATH:$HOME/.scripts" # theme switcher etc. (linked from .system-config)


# ---------------------------------------- claude code ----------------------------------------------
alias cc="claude code"
# Claude Code clamps to 256 colors inside tmux unless told otherwise; tmux
# passes truecolor through (RGB in .tmux.conf), so the custom theme's exact
# hex colors render instead of 256-color approximations
export CLAUDE_CODE_TMUX_TRUECOLOR=1

# ---------------------------------------- cursor agent ---------------------------------------------
alias ca="agent"

# ------------------------------------------ opencode ------------------------------------------------
alias oc="opencode"

# bun completions
[ -s "/Users/renepersau/.bun/_bun" ] && source "/Users/renepersau/.bun/_bun"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
