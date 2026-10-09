#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

# Package inspection and installation helpers.
# Supports python and apt packages.
# Requires common.sh and logging.sh.

shell_utils_python_command() {
    if [ -n "${SHELL_UTILS_PYTHON:-}" ]; then
        printf '%s\n' "$SHELL_UTILS_PYTHON"
    elif shell_utils_command_exists python3; then
        printf '%s\n' python3
    elif shell_utils_command_exists python; then
        printf '%s\n' python
    else
        return 1
    fi
}

python_package_installed() {
    [ "$#" -eq 1 ] || { log_error "Usage: python_package_installed PACKAGE"; return 2; }
    local python_cmd
    python_cmd="$(shell_utils_python_command)" || { log_error "Python was not found."; return 2; }
    "$python_cmd" -m pip show "$1" >/dev/null 2>&1
}

check_python_packages() {
    local package missing=0
    [ "$#" -gt 0 ] || { log_error "Usage: check_python_packages PACKAGE..."; return 2; }
    for package in "$@"; do
        if python_package_installed "$package"; then
            log_info "Python package installed: $package"
        else
            log_warn "Python package missing: $package"
            missing=1
        fi
    done
    return "$missing"
}

install_python_packages() {
    [ "$#" -gt 0 ] || { log_error "Usage: install_python_packages PACKAGE..."; return 2; }
    local python_cmd
    python_cmd="$(shell_utils_python_command)" || { log_error "Python was not found."; return 2; }
    log_info "Installing Python package(s): $*"
    "$python_cmd" -m pip install "$@"
}

apt_package_installed() {
    [ "$#" -eq 1 ] || { log_error "Usage: apt_package_installed PACKAGE"; return 2; }
    shell_utils_command_exists dpkg-query || { log_error "dpkg-query was not found; this system may not be Debian-based."; return 2; }
    [ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null || true)" = "install ok installed" ]
}

check_apt_packages() {
    local package missing=0
    [ "$#" -gt 0 ] || { log_error "Usage: check_apt_packages PACKAGE..."; return 2; }
    for package in "$@"; do
        if apt_package_installed "$package"; then
            log_info "APT package installed: $package"
        else
            log_warn "APT package missing: $package"
            missing=1
        fi
    done
    return "$missing"
}

install_apt_packages() {
    [ "$#" -gt 0 ] || { log_error "Usage: install_apt_packages PACKAGE..."; return 2; }
    shell_utils_command_exists apt-get || { log_error "apt-get was not found; this system may not be Debian-based."; return 2; }

    local privilege
    privilege="$(shell_utils_sudo_command)" || {
        log_error "APT installation requires root privileges or sudo."
        return 1
    }

    log_info "Updating APT package metadata."
    if [ -n "$privilege" ]; then
        if ! "$privilege" apt-get update; then
            log_error "Failed to update APT package metadata."
            return 1
        fi
        log_info "Installing APT package(s): $*"
        if ! "$privilege" apt-get install -y -- "$@"; then
            log_error "Failed to install APT package(s): $*"
            return 1
        fi
    else
        if ! apt-get update; then
            log_error "Failed to update APT package metadata."
            return 1
        fi
        log_info "Installing APT package(s): $*"
        if ! apt-get install -y -- "$@"; then
            log_error "Failed to install APT package(s): $*"
            return 1
        fi
    fi

    log_info "APT package installation complete."
}
