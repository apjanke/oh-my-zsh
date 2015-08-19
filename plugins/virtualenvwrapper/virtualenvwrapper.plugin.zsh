# virtualenvwrapper Oh My Zsh plugin
#
# See README.md for info.
#
# Developer notes:
# Using "omz_venvw" as a prefix for some global names used by this plugin, to avoid collisions. 

# Find and load virtualenvwrapper

() {
# Basic portability protection for virtualenvwrapper, since it doesn't do
# "emulate -L" itself
emulate -L zsh
unsetopt equals

# Locate virtualenvwrapper
local venvw_sh_path
local venvw_sh_name='virtualenvwrapper.sh'
if (( $+commands[$venvw_sh_name] )); then
  venvw_sh_path=${${venvw_sh_name}:c}
elif [[ -f "/etc/bash_completion.d/virtualenvwrapper" ]]; then
  # (this is where Debian and RPM-based distributions install it)
  venvw_sh_path="/etc/bash_completion.d/virtualenvwrapper"
else
  print -l "[oh-my-zsh] virtualenvwrapper plugin: Cannot find ${venvw_sh_name}." \
           "[oh-my-zsh] Please install with \`pip install virtualenvwrapper\`." >&2
  return 1
fi
# Load it and do basic checks
source "$venvw_sh_path"
if ! type workon &>/dev/null; then
  print -l "[oh-my-zsh] virtualenvwrapper plugin: shell function 'workon' not defined."\
           "[oh-my-zsh] Please check ${venvw_sh_path}" >&2
  return 1
fi
if [[ "$WORKON_HOME" == "" ]]; then
  print "[oh-my-zsh] \$WORKON_HOME is not defined so plugin virtualenvwrapper will not work." >&2
  return 1
fi
}
[[ $? != 0 ]] && return 1


function _omz_venvw_debug() {
  if [[ $OMZ_VENVW_DEBUG == 1 ]]; then
    print $@
  fi
}

# workon-cwd
# Automatically activate Git projects or other customized virtualenvwrapper projects based on the
# directory name of the project. Virtual environment name can be overridden
# by placing a .venv file in the project root with a virtualenv name in it.

# Locates project root and venv for the current directory
# Sets $GIT_REPO_ROOT, $PROJECT_ROOT, $ENV_NAME
function _omz_venvw_locate_project() {
  # Check if this is a Git repo
  GIT_REPO_ROOT=""
  local GIT_TOPLEVEL="$(git rev-parse --show-toplevel 2> /dev/null)"
  if [[ $? == 0 ]]; then
    GIT_REPO_ROOT="$GIT_TOPLEVEL"
  fi
  # Get absolute path, resolving symlinks
  PROJECT_ROOT="${PWD:A}"
  while [[ "$PROJECT_ROOT" != "/" && ! -e "$PROJECT_ROOT/.venv" \
           && ! -d "$PROJECT_ROOT/.git"  && "$PROJECT_ROOT" != "$GIT_REPO_ROOT" ]]; do
    PROJECT_ROOT="${PROJECT_ROOT:h}"
  done
  if [[ "$PROJECT_ROOT" == "/" ]]; then
    PROJECT_ROOT="."
  fi
  # Check for virtualenv name override
  if [[ -f "$PROJECT_ROOT/.venv" ]]; then
    ENV_NAME="$(cat "$PROJECT_ROOT/.venv")"
  elif [[ -f "$PROJECT_ROOT/.venv/bin/activate" ]];then
    ENV_NAME="$PROJECT_ROOT/.venv"
  elif [[ "$PROJECT_ROOT" != "." ]]; then
    ENV_NAME="${PROJECT_ROOT:t}"
  else
    ENV_NAME=""
  fi
  _omz_venvw_debug -l "GIT_REPO_ROOT=$GIT_REPO_ROOT" \
     "PROJECT_ROOT=$PROJECT_ROOT" \
     "ENV_NAME=$ENV_NAME"
}

# Debugging version for interactive use
function _omz_venvw_locate_project_debug() {
  local GIT_REPO_ROOT PROJECT_ROOT ENV_NAME
  local OMZ_VENVW_DEBUG=1
  _omz_venvw_locate_project
}

function workon_cwd() {
  if [[ $DISABLE_VENV_CD -eq 1 ]]; then
    return
  fi
  if [[ -n "$IN_WORKON_CWD" ]]; then
    # We were recursively called due to a cd inside an alread-running workon_cwd
    return
  fi
  local GIT_REPO_ROOT PROJECT_ROOT ENV_NAME
  local IN_WORKON_CWD=1
  _omz_venvw_locate_project
  # Avoid "bouncing" up to the project root or venv location
  local VIRTUALENVWRAPPER_WORKON_CD=0
  # Must be exported for subcommands to pick up, and virtualenvwrapper itself does
  # not itself mark it for export if it is already defined
  export VIRTUALENVWRAPPER_WORKON_CD
  if [[ "$ENV_NAME" != "" ]]; then
    # Activate the environment only if it is not already active
    if [[ "$VIRTUAL_ENV" != "${WORKON_HOME%/}/$ENV_NAME" ]]; then
      if [[ -e "$WORKON_HOME/$ENV_NAME/bin/activate" ]]; then
        _omz_venvw_debug "Activating virtualenv $ENV_NAME"
        workon "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
      elif [[ -e "$ENV_NAME/bin/activate" ]]; then
        _omz_venvw_debug "Activating virtualenv $ENV_NAME"
        source $ENV_NAME/bin/activate && export CD_VIRTUAL_ENV="$ENV_NAME"
      else
        _omz_venvw_debug "No virtualenv \"$ENV_NAME\" found. Not activating."
      fi
    fi
  elif [[ -n $CD_VIRTUAL_ENV && -n $VIRTUAL_ENV ]]; then
    # We've just left the repo, deactivate the environment
    # Note: this only happens if the virtualenv was activated automatically
    _omz_venvw_debug "Deactivating virtualenv $CD_VIRTUAL_ENV"
    deactivate && unset CD_VIRTUAL_ENV
  fi
}

# Append workon_cwd to the chpwd_functions array, so it will be called on cd
# http://zsh.sourceforge.net/Doc/Release/Functions.html
if ! (( $chpwd_functions[(I)workon_cwd] )); then
  chpwd_functions+=(workon_cwd)
fi
