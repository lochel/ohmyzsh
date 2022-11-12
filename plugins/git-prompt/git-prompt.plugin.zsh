# Handle $0 according to the standard:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

__GIT_PROMPT_DIR="${0:A:h}"

## Hook function definitions
function chpwd_update_git_vars() {
    update_current_git_vars
}

function preexec_update_git_vars() {
    case "$2" in
        git*|hub*|gh*|stg*)
        __EXECUTED_GIT_COMMAND=1
        ;;
    esac
}

function precmd_update_git_vars() {
    if [ -n "$__EXECUTED_GIT_COMMAND" ] || [ ! -n "$ZSH_THEME_GIT_PROMPT_CACHE" ]; then
        update_current_git_vars
        unset __EXECUTED_GIT_COMMAND
    fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_update_git_vars
add-zsh-hook precmd precmd_update_git_vars
add-zsh-hook preexec preexec_update_git_vars


## Function definitions
function update_current_git_vars() {
    unset __CURRENT_GIT_STATUS

    local gitstatus="$__GIT_PROMPT_DIR/gitstatus.py"
    _GIT_STATUS=$(python3 ${gitstatus} 2>/dev/null)
     __CURRENT_GIT_STATUS=("${(@s: :)_GIT_STATUS}")
    GIT_BRANCH=$__CURRENT_GIT_STATUS[1]
    GIT_AHEAD=$__CURRENT_GIT_STATUS[2]
    GIT_BEHIND=$__CURRENT_GIT_STATUS[3]
    GIT_STAGED=$__CURRENT_GIT_STATUS[4]
    GIT_CONFLICTS=$__CURRENT_GIT_STATUS[5]
    GIT_CHANGED=$__CURRENT_GIT_STATUS[6]
    GIT_UNTRACKED=$__CURRENT_GIT_STATUS[7]
    GIT_STASHED=$__CURRENT_GIT_STATUS[8]
    GIT_CLEAN=$__CURRENT_GIT_STATUS[9]
    GIT_DELETED=$__CURRENT_GIT_STATUS[10]

    if [ -z ${ZSH_THEME_GIT_SHOW_UPSTREAM+x} ]; then
        GIT_UPSTREAM=
    else
        GIT_UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null) && GIT_UPSTREAM="${ZSH_THEME_GIT_PROMPT_UPSTREAM_SEPARATOR}${GIT_UPSTREAM}"
    fi
}

git_super_status() {
    precmd_update_git_vars
    if [ -n "$__CURRENT_GIT_STATUS" ]; then
      STATUS="$ZSH_THEME_GIT_PROMPT_PREFIX$ZSH_THEME_GIT_PROMPT_BRANCH$GIT_BRANCH$GIT_UPSTREAM"
      if [ "$GIT_BEHIND" -ne "0" ]; then
          STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_BEHIND$GIT_BEHIND"
      fi
      if [ "$GIT_AHEAD" -ne "0" ]; then
          STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_AHEAD$GIT_AHEAD"
      fi
      if [ "$GIT_STAGED" -ne "0" ]; then
          STATUS2="$STATUS2$ZSH_THEME_GIT_PROMPT_STAGED$GIT_STAGED"
      fi
      if [ "$GIT_CONFLICTS" -ne "0" ]; then
          STATUS2="$STATUS2$ZSH_THEME_GIT_PROMPT_CONFLICTS$GIT_CONFLICTS"
      fi
      if [ "$GIT_CHANGED" -ne "0" ]; then
          STATUS2="$STATUS2$ZSH_THEME_GIT_PROMPT_CHANGED$GIT_CHANGED"
      fi
      if [ "$GIT_DELETED" -ne "0" ]; then
          STATUS2="$STATUS2$ZSH_THEME_GIT_PROMPT_DELETED$GIT_DELETED"
      fi
      if [ "$GIT_DELETED" -ne "0" ]; then
          STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_DELETED$GIT_DELETED"
      fi
      if [ "$GIT_UNTRACKED" -ne "0" ]; then
          STATUS2="$STATUS2$ZSH_THEME_GIT_PROMPT_UNTRACKED$GIT_UNTRACKED"
      fi
      if [ "$GIT_STASHED" -ne "0" ]; then
          STATUS2="$STATUS2$ZSH_THEME_GIT_PROMPT_STASHED$GIT_STASHED"
      fi
      if [ "$GIT_CLEAN" -eq "1" ]; then
          STATUS2="$STATUS2$ZSH_THEME_GIT_PROMPT_CLEAN"
      fi
      if [ ! -z "$STATUS2" ]; then
          STATUS2=$ZSH_THEME_GIT_PROMPT_SEPARATOR$STATUS2
      fi
      STATUS="$STATUS$STATUS2$ZSH_THEME_GIT_PROMPT_SUFFIX"
      echo "$STATUS"
    fi
}

# Default values for the appearance of the prompt.
ZSH_THEME_GIT_PROMPT_PREFIX="(%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=")%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_SEPARATOR="|%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[red]%}%{●%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[red]%}%{✖%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[blue]%}%{✚%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[blue]%}%{-%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{↓%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{↑%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}%{…%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_STASHED="%{$fg_bold[blue]%}%{⚑%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}%{${reset_color}%}"
ZSH_THEME_GIT_PROMPT_UPSTREAM_SEPARATOR="->"

# Set the prompt.
RPROMPT='$(git_super_status)'
