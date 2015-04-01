# Constructs the git info section of the prompt
function git_prompt_info() {
  if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" != "1" ]]; then
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
    echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
  fi
}


# A simple clean/dirty status check
# Outputs a brief clean/dirty/timeout string that indicates whether the repo has uncommitted changes.
# This is in contrast to git_prompt_info, which provdes a
# lengthier status string with more possible indicators.
# This quick test does not require the full output of `git status`
function parse_git_dirty() {
  local FLAGS
  local OMZ_TMPDIR=$TMPDIR/oh-my-zsh
  # Always use visible error indicator even if theme doesn't define one, to avoid silently
  # looking like a clean directory when we can't get info
  local TIMEDOUT_TXT=${ZSH_THEME_GIT_PROMPT_TIMEDOUT:-???}
  if [[ ! -d $OMZ_TMPDIR ]]; then
    mkdir -p $OMZ_TMPDIR || (echo $TIMEDOUT_TXT && return)
  fi
  FLAGS=('--porcelain')
  if [[ "$(command git config --get oh-my-zsh.hide-dirty)" != "1" ]]; then
    if [[ $POST_1_7_2_GIT -gt 0 ]]; then
      FLAGS+='--ignore-submodules=dirty'
    fi
    if [[ $DISABLE_UNTRACKED_FILES_DIRTY == "true" ]]; then
      FLAGS+='--untracked-files=no'
    fi
    # Use a serverized git run to timebox `git status` so slow repo access doesn't hang the prompt
    local GIT_FIFO=$OMZ_TMPDIR/omz-parse_git_dirty-git-status.$$
    # Clean up any leftover from previous aborted run
    [[ -f $GIT_FIFO ]] && rm -f $GIT_FIFO
    mkfifo $GIT_FIFO || (echo $TIMEDOUT_TXT && return)
    command git status ${FLAGS} >$GIT_FIFO 2>/dev/null &
    local GIT_PID=$!
    # Use dummy "__unset__" to distinguish timeouts from empty output
    local STATUS=__unset__
    read -t $ZSH_THEME_SCM_CHECK_TIMEOUT STATUS <$GIT_FIFO
    rm $GIT_FIFO
    if [[ $STATUS == __unset__ ]]; then
      # Variable didn't get set = read timeout
      echo $TIMEDOUT_TXT
      # Get rid of that git run if it's still going
      kill -s KILL $GIT_PID &>/dev/null
    elif [[ -z $STATUS ]]; then
      echo $ZSH_THEME_GIT_PROMPT_CLEAN
    else
      echo $ZSH_THEME_GIT_PROMPT_DIRTY
    fi
  fi
}

# Gets the difference between the local and remote branches
function git_remote_status() {
    remote=${$(command git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/}
    if [[ -n ${remote} ]] ; then
        ahead=$(command git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
        behind=$(command git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)

        if [ $ahead -eq 0 ] && [ $behind -gt 0 ]
        then
            echo "$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE"
        elif [ $ahead -gt 0 ] && [ $behind -eq 0 ]
        then
            echo "$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE"
        elif [ $ahead -gt 0 ] && [ $behind -gt 0 ]
        then
            echo "$ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE"
        fi
    fi
}

# Checks if there are commits ahead from remote
function git_prompt_ahead() {
  if $(echo "$(command git log @{upstream}..HEAD 2> /dev/null)" | grep '^commit' &> /dev/null); then
    echo "$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
}

# Gets the number of commits ahead from remote
function git_commits_ahead() {
  if $(echo "$(command git log @{upstream}..HEAD 2> /dev/null)" | grep '^commit' &> /dev/null); then
    COMMITS=$(command git log @{upstream}..HEAD | grep '^commit' | wc -l | tr -d ' ')
    echo "$ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX$COMMITS$ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX"
  fi
}

# Formats prompt string for current git commit short SHA
function git_prompt_short_sha() {
  SHA=$(command git rev-parse --short HEAD 2> /dev/null) && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}

# Formats prompt string for current git commit long SHA
function git_prompt_long_sha() {
  SHA=$(command git rev-parse HEAD 2> /dev/null) && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}

# Get the status of the working tree
function git_prompt_status() {
  #TODO: Timebox these `git status` calls, too
  _git_prompt_status_zsh_parse
}

# got_prompt_status implementation that parses status output using built-in zsh features
function _git_prompt_status_zsh_parse() {
  local -a flags git_status
  if [[ $DISABLE_UNTRACKED_FILES_DIRTY == "true" ]]; then
    flags+='--untracked-files=no'
  fi
  git_status=("${(@f)$(command git status --porcelain -b $flags 2> /dev/null)}")
  if [[ $? != 0 ]]; then
    # Not in a git directory; we can skip other checks
    return 0
  fi
  # This parsing logic is faster than doing repeated shell-outs to grep, and probably more
  # accurate because it can check the "X" and "Y" codes independently
  local -A has
  local line code x y branch_status
  local is_ahead is_behind
  for line ($git_status); do
    code=${line[1,2]}
    x=${line[1]}
    y=${line[2]}
    is_ahead='n'
    is_behind='n'
    if [[ $x == '?' || $y == '?' ]]; then
      has[untracked]='y'
    fi
    if [[ $x == 'D' || $y == 'D' ]]; then
      has[deleted]='y'
    fi
    if [[ $x == 'R' ]]; then
      has[renamed]='y'
    fi
    if [[ $x == 'A' || $x == 'C' ]]; then
      has[added]='y'
    fi
    if [[ $x == 'M' || $y == 'M' || $y == 'T' ]]; then
      has[modified]='y'
    fi
    if [[ $x == 'U' || $y == 'U' ]]; then
      has[unmerged]='y'
    fi
    if [[ $code == '##' ]]; then
      if [[ $line =~ '\[.*\]$' ]]; then
        branch_status=$MATCH
        [[ $branch_status =~ 'ahead' ]] && is_ahead='y'
        [[ $branch_status =~ 'behind' ]] && is_behind='y'
        if [[ $branch_status =~ 'diverged' || ( $is_ahead == 'y' && $is_behind == 'y' ) ]]; then
          has[diverged]='y'
        elif [[ $is_ahead == 'y' ]]; then
          has[ahead]='y'
        elif [[ $is_behind == 'y' ]]; then
          has[behind]='y'
        fi
      fi
    fi
    if [[ ${#has} == 9 ]]; then
      # We've hit all the possibilities and all bits are on; no need to keep parsing
      break
    fi
  done

  STATUS=""
  if $(command git rev-parse --verify refs/stash >/dev/null 2>&1); then
    STATUS+=$ZSH_THEME_GIT_PROMPT_STASHED
  fi
  [[ ${has[diverged]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_DIVERGED
  [[ ${has[behind]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_BEHIND
  [[ ${has[ahead]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_AHEAD
  [[ ${has[unmerged]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_UNMERGED
  [[ ${has[deleted]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_DELETED
  [[ ${has[renamed]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_RENAMED
  [[ ${has[modified]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_MODIFIED
  [[ ${has[added]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_ADDED
  [[ ${has[untracked]} == 'y' ]] && STATUS+=$ZSH_THEME_GIT_PROMPT_UNTRACKED

  echo $STATUS
}

# git_prompt_status implementation that shells out ot grep
# This is the original implmentation. I'm keeping it around for now to allow 
# comparative benchmarking.
function _git_prompt_status_grep() {
  INDEX=$(command git status --porcelain -b 2> /dev/null)
  STATUS=""
  if $(echo "$INDEX" | command grep -E '^\?\? ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_UNTRACKED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^A  ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_ADDED$STATUS"
  elif $(echo "$INDEX" | grep '^M  ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_ADDED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^ M ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
  elif $(echo "$INDEX" | grep '^AM ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
  elif $(echo "$INDEX" | grep '^ T ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^R  ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_RENAMED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^ D ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS"
  elif $(echo "$INDEX" | grep '^D  ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS"
  elif $(echo "$INDEX" | grep '^AD ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS"
  fi
  if $(command git rev-parse --verify refs/stash >/dev/null 2>&1); then
    STATUS="$ZSH_THEME_GIT_PROMPT_STASHED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^UU ' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_UNMERGED$STATUS"
  fi
  if $(echo "$INDEX" | grep '^## .*ahead' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_AHEAD$STATUS"
  fi
  if $(echo "$INDEX" | grep '^## .*behind' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_BEHIND$STATUS"
  fi
  if $(echo "$INDEX" | grep '^## .*diverged' &> /dev/null); then
    STATUS="$ZSH_THEME_GIT_PROMPT_DIVERGED$STATUS"
  fi
  echo $STATUS
}


# Compares the provided version of git to the version installed and on path
# Prints 1 if installed version > input version
# Prints -1 if installed version < input version
# Prints 0 if installed version = input version
# Always returns 0
function _git_compare_version() {
  local INPUT_GIT_VERSION=$1;
  local INSTALLED_GIT_VERSION
  INPUT_GIT_VERSION=(${(s/./)INPUT_GIT_VERSION});
  INSTALLED_GIT_VERSION=($(command git --version 2>/dev/null));
  INSTALLED_GIT_VERSION=(${(s/./)INSTALLED_GIT_VERSION[3]});

  for i in {1..3}; do
    if [[ $INSTALLED_GIT_VERSION[$i] -gt $INPUT_GIT_VERSION[$i] ]]; then
      echo 1
      return 0
    fi
    if [[ $INSTALLED_GIT_VERSION[$i] -lt $INPUT_GIT_VERSION[$i] ]]; then
      echo -1
      return 0
    fi
  done
  echo 0
}

# This is unlikely to change so make it all statically assigned
POST_1_7_2_GIT=$(_git_compare_version "1.7.2")
# Clean up the namespace slightly by removing the checker function
unset -f _git_compare_version
