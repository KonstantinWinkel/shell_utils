# shell-utils

A small BASH utility library I made to reduce the amount of duplicated code in many of my projects. It provides timestamped coloured logging, Python and APT package checks/installers, git repository updates, and individual git submodule initialisation.

Requires BASH 4 or newer

## 1. Installation

Copy the `shell-utils` directory into your project, for example under `tools/shell-utils`, and source the public entry point:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tools/shell-utils/shell-utils.sh"
```

The library does not enable `set -e`, `set -u`, or `pipefail`; the calling script retains control of its shell options.


## 2. Features
### 2.1. Logging

```bash
log_debug "Detailed diagnostic message"
log_info "Setup started"
log_warn "Optional dependency is missing"
log_error "Setup failed"
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

The installer runs `apt-get update` followed by non-interactive `apt-get install -y`. It uses the current process when running as root and otherwise uses `sudo`.

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


## 3. Tests

The tests are offline and do not install packages or contact remotes:

```bash
bash tests/run_tests.sh
```

Optional static analysis:

```bash
shellcheck shell-utils.sh lib/*.sh examples/*.sh tests/*.sh
```

## 4. Return codes

- `0`: operation succeeded or requested item is installed
- `1`: operation failed, item is missing, or one item in a batch failed
- `2`: invalid usage or a required platform tool is unavailable
