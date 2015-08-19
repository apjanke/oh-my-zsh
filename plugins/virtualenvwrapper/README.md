#  Virtualenvwrapper Plugin  #

The Oh My Zsh virtualenvwrapper plugin is a set of Zsh extensions to [virtualenvwrapper](http://virtualenvwrapper.readthedocs.org/en/latest/), which is a set of extensions to [virtualenv](https://pypi.python.org/pypi/virtualenv), which is an extension to Python's setup and library management system.

The OMZ virtualenvwrapper plugin provides these features:

* Finding and loading virtualenvwrapper on shell startup
* Adding a `chpwd` hook to automatically activate a virtualenv when you cd in to a directory associated with one

##   Requirements   ##

Requires:
* Python
* virtualenvwrapper 4.4.0 or later

Use `pip install virtualenvwrapper` to install virtualenvwrapper. Virtualenvwrapper must be installed either on the path or in the default Debian/RPM-based location.

##   Project Directories and workon-cwd   ##

If the workon-cwd feature is enabled, when you cd in to a project directory or a subdirectory of one, the virtualenv corresponding to it will be activated. Workon-cwd is enabled by default, and can be disabled by setting `DISABLE_VENV_CD=1`.

A "project directory" is one of:
* A git repo root, in which case the basename of the directory is taken as the virtualenv name
* A directory with a `.venv` file which contains the virtualenv name to use
* A directory with a `.venv` subdirectory which contains a local virtualenv

The lowermost project directory in the path to your current directory takes precedence.

##   Variables   ##

Variables used by this plugin:

* `$WORKON_HOME` - Location of your virtualenvs.
* `$DISABLE_VENV_CD` - Set to 'true' to turn off workon-cwd.

* `$IN_WORKON_CWD` - Used to indicate the chpwd hook is running. Setting this to nonempty will effectively disable workon_cwd.
* `$VIRTUAL_ENV` - The current virtualenv. Provided by virtualenvwrapper.

Variables set by this plugin:

* `$ENV_NAME` - Name or path of virtualenv selected based on project directory.
* `$CD_VIRTUAL_ENV` - Virtualenv which was activated by workon-cwd.


