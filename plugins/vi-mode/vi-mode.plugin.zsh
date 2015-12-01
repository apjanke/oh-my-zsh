# Updates editor information when the keymap changes.
function zle-keymap-select() {
  zle reset-prompt
  zle -R
}

# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
  zle && { zle reset-prompt; zle -R }
}

zle -N zle-keymap-select
zle -N edit-command-line


bindkey -v

# allow v to edit the command line (standard behaviour)
autoload -Uz edit-command-line
bindkey -M vicmd 'v' edit-command-line

# allow ctrl-p, ctrl-n for navigate history (standard behaviour)
bindkey '^P' up-history
bindkey '^N' down-history

# allow ctrl-h, ctrl-w, ctrl-? for char and word deletion (standard behaviour)
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

# Runs a bindkey command for both vi keymaps
function bindkey_both_vi() {
  bindkey -M viins "$@"
  bindkey -M vicmd "$@"
}

# Navigation keys
if [[ "${terminfo[kpp]}" != "" ]]; then
  bindkey_both_vi "${terminfo[kpp]}" up-line-or-history       # [PageUp] - Up a line of history
fi
if [[ "${terminfo[knp]}" != "" ]]; then
  bindkey_both_vi "${terminfo[knp]}" down-line-or-history     # [PageDown] - Down a line of history
fi
if [[ "${terminfo[khome]}" != "" ]]; then
  bindkey_both_vi "${terminfo[khome]}" beginning-of-line      # [Home] - Go to beginning of line
fi
if [[ "${terminfo[kend]}" != "" ]]; then
  bindkey_both_vi "${terminfo[kend]}"  end-of-line            # [End] - Go to end of line
fi
bindkey_both_vi '^[[1;5C' forward-word                        # [Ctrl-RightArrow] - move forward one word
bindkey_both_vi '^[[1;5D' backward-word                       # [Ctrl-LeftArrow] - move backward one word
if [[ "${terminfo[kdch1]}" != "" ]]; then
  bindkey_both_vi "${terminfo[kdch1]}" delete-char            # [Delete] - delete forward
else
  bindkey_both_vi "^[[3~" delete-char
  bindkey_both_vi "^[3;5~" delete-char
  bindkey_both_vi "\e[3~" delete-char
fi


# if mode indicator wasn't setup by theme, define default
if [[ "$MODE_INDICATOR" == "" ]]; then
  MODE_INDICATOR="%{$fg_bold[red]%}<%{$fg[red]%}<<%{$reset_color%}"
fi

function vi_mode_prompt_info() {
  echo "${${KEYMAP/vicmd/$MODE_INDICATOR}/(main|viins)/}"
}

# define right prompt, if it wasn't defined by a theme
if [[ "$RPS1" == "" && "$RPROMPT" == "" ]]; then
  RPS1='$(vi_mode_prompt_info)'
fi
