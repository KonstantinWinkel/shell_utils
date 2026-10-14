# shell-utils

A small BASH utility library I made to reduce the amount of duplicated code in many of my projects. It provides timestamped and coloured logging, Python and APT package checks/installers, git repository updates, individual git submodule initialisation and cleanup utility.

Requires BASH 4 or newer.

## 0. A note on security
This library has been designed as a tool for developers. Measures have been taken where possible to mitegate possible security vulnerabilities like arbitrary code execution or arbitrary file deletion, however in some cases it is not possible to fully avoid these vulnerabilities without restricting or removing features (e.g. custom python interpreter paths). \
As a rule of thumb: **DO NOT USE THIS LIBRARY WITH UNTRUSTED SOURCES OR UNCHECKED USER INPUT**. However, if you must, take measures to check, sanatize and if needed reject user input.\
Stay safe.

## 1. Installation

Copy the `shell-utils` directory into your project. It should be in the top project directory:

```tree
Your Project
├── shell-utils
└── ...
```
From there source the library entry point:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shell-utils/shell-utils.sh"
```

The entry point loads all library modules. The public functions described below are then available to the calling script.

## 2. Library variables and return codes

Set these variables before calling the relevant functions to change library behaviour.

| Variable | Type | Allowed values | Description |
| -------- | ---- | -------------- | ----------- |
| `SHELL_UTILS_PYTHON` | Executable path | Any executable regular file | Selects a specific Python interpreter or virtual environment. If unset, the library uses `python3`, then `python`. See [3.2. Python packages](#32-python-packages). |
| `SHELL_UTILS_GIT_STRICT` | Integer | `0` / `1` | When set to `1`, rejects `file://` and unknown Git remote protocols without prompting. See [3.4. Git repositories](#34-git-repositories). |
| `SHELL_UTILS_LOG_LEVEL` | String | `DEBUG`, `INFO`, `WARN`, `WARNING`, `ERROR` | Sets the minimum emitted log level. Invalid values fall back to `INFO` behaviour. |
| `NO_COLOR` | Any non-empty value | - | Disables coloured log output. Colours are also disabled automatically when stderr is not an interactive terminal. |

General return-code convention:

- `0`: the operation succeeded or the requested item is installed
- `1`: the operation failed, the requested item is missing, or at least one item in a batch failed
- `2`: invalid usage, an unsafe or unsupported argument, or a required platform tool is unavailable

Functions that directly execute `git`, `pip`, or another platform command may also propagate a non-zero status from that command.

## 3. Features
### 3.1. Logging

```bash
log_debug "Diagnostic message"
log_info "Info Message"
log_warn "Warning Message"
log_error "Error Message"
```

Messages are written to stderr with a local timestamp and level. Control characters in messages are replaced so that each event remains on one log line and cannot inject terminal control sequences.

Colours are enabled only when stderr is an interactive terminal. Set `NO_COLOR=1` to disable colour explicitly. Set `SHELL_UTILS_LOG_LEVEL` to control verbosity:

```bash
SHELL_UTILS_LOG_LEVEL=DEBUG
log_debug "Visible diagnostic message"
```

### 3.2. Python packages

```bash
python_package_installed pyside6
check_python_packages sarif-tools pyside6
install_python_packages sarif-tools pyside6
install_python_packages_strict pyside6
```
`python_package_installed` checks whether a single python package is installed \
`check_python_packages` returns success only when every named package is installed. \
`install_python_packages` installs all python packages using `{python_interpreter} -m pip`. Arguments are passed directly to `pip`, so requirement files and other options are supported. \
`install_python_packages_strict` installs all python packages using `{python_interpreter} -m pip`. Only package names with version informations are permitted as arguments. Other options are rejected. \
Set `SHELL_UTILS_PYTHON` to select a specific interpreter or virtual environment:

- `python_package_installed PACKAGE` checks whether one package is installed using `python -m pip show`. Option-like package names are rejected.
- `check_python_packages PACKAGE...` returns success only when every named package is installed.
- `install_python_packages ARGUMENT...` passes all arguments directly to `python -m pip install`. This supports requirement files and other pip options, but arguments must therefore be trusted.
- `install_python_packages_strict PACKAGE...` rejects arguments beginning with `-` before delegating to `install_python_packages`. It supports ordinary package names and version specifiers, but it does not validate or require version pinning and must not be treated as a complete validator for untrusted input.

Set `SHELL_UTILS_PYTHON` to select a specific interpreter or virtual environment. The path must refer to an executable regular file:

```bash
SHELL_UTILS_PYTHON="$PROJECT_ROOT/.venv/bin/python"
install_python_packages -r requirements.txt
```

### 3.3. APT packages

```bash
apt_package_installed git
check_apt_packages git curl
install_apt_packages git curl
```

- `apt_package_installed PACKAGE` checks one package using `dpkg-query`. Option-like package names are rejected.
- `check_apt_packages PACKAGE...` returns success only when every named package is installed.
- `install_apt_packages PACKAGE...` runs `apt-get update`, followed by non-interactive `apt-get install -y -- PACKAGE...`.

These functions target Debian-based systems. Installation runs directly when the current process is root; otherwise, it uses `sudo`. If neither root privileges nor `sudo` are available, installation fails without attempting `apt-get`.

### 3.4. Git repositories

```bash
update_git_repository "/path/to/repository"
update_git_repository "/path/to/repository" upstream
update_git_repository "/path/to/repository" upstream main
update_git_repositories repo-one repo-two repo-three
```

`update_git_repository [REPOSITORY [REMOTE [BRANCH]]]` uses `.` as the default repository and `origin` as the default remote. The current branch is detected automatically unless a branch is supplied. A detached HEAD therefore requires an explicit branch.

Updates use `git fetch --prune` followed by `git pull --rebase`. A dirty working tree produces a warning but is not modified or stashed automatically. Remote and branch names beginning with `-` are rejected, and explicit branch names are checked with `git check-ref-format --branch`.

HTTP, HTTPS, unauthenticated Git, and SSH-style remote URLs are accepted directly. Remotes using the `ext::` transport are always rejected. `file://` and unknown remote protocols require interactive confirmation and are rejected in non-interactive environments. Set `SHELL_UTILS_GIT_STRICT=1` to reject `file://` and unknown protocols without prompting.

`update_git_repositories REPOSITORY...` updates each supplied repository. It continues after an individual failure and returns `1` if any update failed.

### 3.5. Git submodules

```bash
list_git_submodules "/path/to/repository"
init_git_submodule "/path/to/repository" "vendor/specific-module"
```

`list_git_submodules [REPOSITORY]` prints the paths declared in `.gitmodules`, one per line. It uses the current directory by default and succeeds without output if the repository has no `.gitmodules` file.

`init_git_submodule REPOSITORY SUBMODULE_PATH` validates the requested path against `.gitmodules`, then initialises only that submodule and its nested submodules. Paths containing spaces are preserved.

### 3.6. Cleaning

```bash
clean_python_cache "/path/to/dir"
```

`clean_python_cache ROOT_DIRECTORY` recursively removes directories named `__pycache__` without crossing filesystem boundaries.

For deletion safety, the resolved cleanup root must be the directory containing the `shell-utils` library or one of that directory's descendants. Requests outside this allowed tree are rejected. The function reports the number of matching directories found before deletion.

## 4. Tests

The offline test suite exercises logging, command detection, package checks, Git remote validation, submodule path handling, and cleanup boundary checks. It does not install packages or contact remotes.

Run it from the project root:

```bash
bash tests/run_tests.sh
```
