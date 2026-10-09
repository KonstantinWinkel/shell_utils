# shell-utils

A small BASH utility library I made to reduce the amount of duplicated code in many of my projects. It provides timestamped and coloured logging, Python and APT package checks/installers, git repository updates, individual git submodule initialisation and cleanup utility.

Requires BASH 4 or newer.

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

## 2. Features
### 2.1. Logging

```bash
log_debug "Diagnostic message"
log_info "Info Message"
log_warn "Warning Message"
log_error "Error Message"
```

Messages are written to stderr with a local timestamp. Colours are enabled only for an interactive terminal. Set `NO_COLOR=1` to disable colour explicitly. Set `SHELL_UTILS_LOG_LEVEL=DEBUG`, `INFO`, `WARN`, or `ERROR` to control verbosity.

### 2.2. Python packages

```bash
python_package_installed pyside6
check_python_packages sarif-tools pyside6
install_python_packages sarif-tools pyside6
```

`check_python_packages` returns success only when every named package is installed. `install_python_packages` uses `python3 -m pip` where possible. Set `SHELL_UTILS_PYTHON` to select a specific interpreter or virtual environment:

```bash
SHELL_UTILS_PYTHON="$PROJECT_ROOT/.venv/bin/python"
install_python_packages -r requirements.txt
```

Arguments are passed directly to `pip install`, so requirements files, version constraints, and other pip options are supported.

### 2.3 APT packages

```bash
apt_package_installed git
check_apt_packages git curl
install_apt_packages git curl
```

Similar to the python package utility. The installer runs `apt-get update` followed by non-interactive `apt-get install -y`. It uses the current process when running as root and otherwise uses `sudo`.

### 2.4 Git repositories

```bash
update_git_repository "/path/to/repository"
update_git_repository "/path/to/repository" upstream main
update_git_repositories repo-one repo-two repo-three
```

The default remote is `origin`. The current branch is detected automatically unless a branch is supplied. Updates use `fetch --prune` and `pull --rebase`. A dirty working tree produces a warning but is not modified or stashed automatically.

### 2.5 Git submodules

```bash
list_git_submodules "/path/to/repository"
init_git_submodule "/path/to/repository" "vendor/specific-module"
```

`init_git_submodule` validates the path against `.gitmodules`, then initialises only that submodule and its nested submodules.

### 2.6 Cleaning

```bash
clean_python_cache "/path/to/dir"
```

`clean_python_cache` goes through all folders recursively and removes all `__pycache__` folders. This operation is limited to all folders in the parent of the shell-utils library.

## 3. Tests

Testsuite to show all functionalities work as intented. These tests are offline and do not install packages or contact remotes:

```bash
bash tests/run_tests.sh
```

## 4. Return codes

- `0`: operation succeeded or requested item is installed
- `1`: operation failed, item is missing, or one item in a batch failed
- `2`: invalid usage or a required platform tool is unavailable
