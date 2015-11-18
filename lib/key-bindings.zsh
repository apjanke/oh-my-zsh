# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# Make sure that the terminal is in keypad application mode when zle is active, since
# only then are all values from $terminfo valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# Binds a key using terminfo mappings, only if that key is defined 
# for this terminal
function omz_bindkey() {
  emulate -L zsh
  local cap=$1 widget=$2
  if [[ -n "${terminfo[$cap]}" ]]; then
    bindkey "${terminfo[$cap]}" $widget
  else
    return 1
  fi
}

bindkey -e                                        # Use emacs key bindings

bindkey '\ew' kill-region                         # [Esc-w] - Kill from the cursor to the mark
bindkey -s '\el' 'ls\n'                           # [Esc-l] - run command: ls
bindkey '^r' history-incremental-search-backward  # [Ctrl-r] - Search backward incrementally for a specified string. 
                                                  #    The string may begin with ^ to anchor the search to the beginning of the line.

omz_bindkey   kpp    up-line-or-history           # [PageUp] - Up a line of history
omz_bindkey   knp    down-line-or-history         # [PageDown] - Down a line of history
omz_bindkey   kcuu1  up-line-or-search            # start typing + [Up-Arrow] - fuzzy find history forward
omz_bindkey   kcud1  down-line-or-search          # start typing + [Down-Arrow] - fuzzy find history backward
omz_bindkey   khome  beginning-of-line            # [Home] - Go to beginning of line
omz_bindkey   kend   end-of-line                  # [End] - Go to end of line
bindkey '\e[1;5C' forward-word                    # [Ctrl-RightArrow] - move forward one word
bindkey '\e[1;5D' backward-word                   # [Ctrl-LeftArrow] - move backward one word

bindkey       ' '    magic-space                  # [Space] - do history expansion

omz_bindkey   kcbt   reverse-menu-complete        # [Shift-Tab] - move through the completion menu backwards

bindkey       '^?'   backward-delete-char         # [Backspace] - delete backward
omz_bindkey   kdch1  delete-char                  # [Delete] - delete forward
if [[ $? != 0 ]]; then
  # Alternate forward-delete sequences, if not in terminfo
  bindkey '\e[3~' delete-char    # VT220
  bindkey '\e3;5~' delete-char   # I don't know what this is, but it was here before -apjanke
fi

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# File rename magick
bindkey '\em' copy-prev-shell-word

# Consider additional emacs keybindings:

#bindkey '\e[A' up-line-or-search
#bindkey '\e[B' down-line-or-search
#bindkey '\e\e[C' emacs-forward-word
#bindkey '\e\e[D' emacs-backward-word
#
#bindkey -s '^X^Z' '%-^M'
#bindkey '\ee' expand-cmd-path
#bindkey '\e^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history
#bindkey '^W' kill-region
#bindkey '^I' complete-word
