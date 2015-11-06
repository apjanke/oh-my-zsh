# Sunrise theme for oh-my-zsh
# Intended to be used with Solarized: http://ethanschoonover.com/solarized
# (Needs Git plugin for current_branch method)

# Get the status of the working tree (copied and modified from git.zsh)
custom_git_prompt_status() {
  local INDEX
  INDEX=$(git status --porcelain 2> /dev/null)
  local STATUS=""
  # Non-staged
  if $(echo "$INDEX" | grep '^?? ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_UNTRACKED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^UU ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_UNMERGED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^ D ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^.M ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
  elif $(echo "$INDEX" | grep '^AM ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
  elif $(echo "$INDEX" | grep '^ T ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
  fi
  # Staged
  if $(echo "$INDEX" | grep '^D  ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_DELETED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^R' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_RENAMED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^M' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_MODIFIED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^A' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_STAGED_ADDED$STATUS"
  fi

  if $(echo -n "$STATUS" | grep '.*' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_STATUS_PREFIX$STATUS"
  fi

  echo $STATUS
}

# get the name of the branch we are on (copied and modified from git.zsh)
function custom_git_prompt() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$(git_prompt_ahead)$(custom_git_prompt_status)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

() {

# Color shortcuts
local R=$fg_no_bold[red]
local G=$fg_no_bold[green]
local M=$fg_no_bold[magenta]
local Y=$fg_no_bold[yellow]
local B=$fg_no_bold[blue]
local RESET=$reset_color

if [ "$USER" = "root" ]; then
    local PROMPTCOLOR="%{$R%}" 
    local PROMPTPREFIX="-!-";
else
    local PROMPTCOLOR="" 
    local PROMPTPREFIX="---";
fi


# %B sets bold text
PROMPT='%B$PROMPTPREFIX %2~ $(custom_git_prompt)%F{magenta}%B»%b%f '
RPS1="%(?..%F{red}%? ↵%f)"


ZSH_THEME_GIT_PROMPT_PREFIX="%{$Y%}‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$Y%}›%{$RESET%} "

ZSH_THEME_GIT_PROMPT_DIRTY="%{$R%}*"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_AHEAD="%{$B%}➔"

ZSH_THEME_GIT_STATUS_PREFIX=" "

# Staged
ZSH_THEME_GIT_PROMPT_STAGED_ADDED="%{$G%}A"
ZSH_THEME_GIT_PROMPT_STAGED_MODIFIED="%{$G%}M"
ZSH_THEME_GIT_PROMPT_STAGED_RENAMED="%{$G%}R"
ZSH_THEME_GIT_PROMPT_STAGED_DELETED="%{$G%}D"

# Not-staged
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$R%}?"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$R%}M"
ZSH_THEME_GIT_PROMPT_DELETED="%{$R%}D"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$R%}UU"

}
