#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

# Package inspection and installation helpers.
# Supports python and apt packages.
# Requires common.sh and logging.sh.

shell_utils_python_command() {
    if [ -n "${SHELL_UTILS_PYTHON:-}" ]; then
        # Validate the path is an executable file
        if [ -x "$SHELL_UTILS_PYTHON" ] && [ -f "$SHELL_UTILS_PYTHON" ]; then
            printf '%s\n' "$SHELL_UTILS_PYTHON"
        else
            log_error "SHELL_UTILS_PYTHON is set but not an executable file: $SHELL_UTILS_PYTHON"
        fi
    elif shell_utils_command_exists python3; then
        printf '%s\n' python3
    elif shell_utils_command_exists python; then
        printf '%s\n' python
    else
        return 1
    fi
}

python_package_installed() {
    [ "$#" -eq 1 ] || { log_error "Usage: python_package_installed REQUIREMENT"; return 2; }
    [ "${1#-}" = "$1" ] || { log_error "Invalid Python requirement: $1"; return 2; }

    local requirement="$1" package operator required_version python_cmd installed_version

    if [[ "$requirement" =~ ^([A-Za-z0-9][A-Za-z0-9._-]*)(==|!=|\>=|\<=|\>|\<)([A-Za-z0-9][A-Za-z0-9._+-]*)$ ]]; then
        package="${BASH_REMATCH[1]}"
        operator="${BASH_REMATCH[2]}"
        required_version="${BASH_REMATCH[3]}"
    elif [[ "$requirement" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        package="$requirement"
        operator=""
        required_version=""
    else
        log_error "Invalid or unsupported Python requirement: $requirement"
        return 2
    fi

    python_cmd="$(shell_utils_python_command)" || { log_error "Python was not found."; return 2; }
    installed_version="$(
        "$python_cmd" -m pip show -- "$package" 2>/dev/null |
            while IFS=: read -r key value; do
                if [ "$key" = "Version" ]; then
                    value="${value# }"
                    printf '%s\n' "$value"
                    break
                fi
            done
    )"
    [ -n "$installed_version" ] || return 1
    [ -n "$operator" ] || return 0

    case "$operator" in
        '==') [ "$installed_version" = "$required_version" ] ;;
        '!=') [ "$installed_version" != "$required_version" ] ;;
        '>=') [ "$(printf '%s\n%s\n' "$required_version" "$installed_version" | sort -V | head -n 1)" = "$required_version" ] ;;
        '<=') [ "$(printf '%s\n%s\n' "$installed_version" "$required_version" | sort -V | head -n 1)" = "$installed_version" ] ;;
        '>')
            [ "$installed_version" != "$required_version" ] &&
                [ "$(printf '%s\n%s\n' "$required_version" "$installed_version" | sort -V | head -n 1)" = "$required_version" ]
            ;;
        '<')
            [ "$installed_version" != "$required_version" ] &&
                [ "$(printf '%s\n%s\n' "$installed_version" "$required_version" | sort -V | head -n 1)" = "$installed_version" ]
            ;;
    esac
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


# SECURITY NOTE: This functions argument are passed to "pip install" without validation. Do not pass
#                untrusted user input to this function without sanatization, as pip options could be
#                injected (like installation from arbitrary sources using -e git+hattps://...).
install_python_packages() {
    [ "$#" -gt 0 ] || { log_error "Usage: install_python_packages PACKAGE..."; return 2; }
    local python_cmd
    python_cmd="$(shell_utils_python_command)" || { log_error "Python was not found."; return 2; }
    log_info "Installing Python package(s): $*"
    "$python_cmd" -m pip install "$@"
}

install_python_packages_strict() {
    [ "$#" -gt 0 ] || { log_error "Usage: install_python_packages_strict PACKAGE..."; return 2; }
    local package
    for package in "$@"; do
        [ "${package#-}" = "$package" ] || {
            log_error "Option-like package name refused by strict installation: $package"
            return 2
        }
    done
    install_python_packages "$@"
}

uninstall_python_packages() {
    [ "$#" -gt 0 ] || { log_error "Usage: uninstall_python_packages PACKAGE..."; return 2; }
    local package python_cmd
    for package in "$@"; do
        if ! [[ "$package" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
            log_error "Invalid Python package name: $package"
            return 2
        fi
    done
    python_cmd="$(shell_utils_python_command)" || { log_error "Python was not found."; return 2; }
    log_info "Uninstalling Python package(s): $*"
    if ! "$python_cmd" -m pip uninstall -y "$@"; then
        log_error "Failed to uninstall Python package(s): $*"
        return 1
    fi
    log_info "Python package uninstallation complete."
}

apt_package_installed() {
    [ "$#" -eq 1 ] || { log_error "Usage: apt_package_installed PACKAGE"; return 2; }
    [ "${1#-}" = "$1" ] || { log_error "Invalid package name: $1"; return 2; }
    shell_utils_command_exists dpkg-query || { log_error "dpkg-query was not found; this system may not be Debian-based."; return 2; }
    [ "$(dpkg-query -W -f='${Status}' -- "$1" 2>/dev/null || true)" = "install ok installed" ]
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

uninstall_apt_packages() {
    [ "$#" -gt 0 ] || { log_error "Usage: uninstall_apt_packages PACKAGE..."; return 2; }
    local package privilege
    for package in "$@"; do
        [ "${package#-}" = "$package" ] || {
            log_error "Invalid package name: $package"
            return 2
        }
    done
    shell_utils_command_exists apt-get || { log_error "apt-get was not found; this system may not be Debian-based."; return 2; }
    privilege="$(shell_utils_sudo_command)" || {
        log_error "APT uninstallation requires root privileges or sudo."
        return 1
    }
    log_info "Uninstalling APT package(s): $*"
    if [ -n "$privilege" ]; then
        if ! "$privilege" apt-get remove -y -- "$@"; then
            log_error "Failed to uninstall APT package(s): $*"
            return 1
        fi
    else
        if ! apt-get remove -y -- "$@"; then
            log_error "Failed to uninstall APT package(s): $*"
            return 1
        fi
    fi
    log_info "APT package uninstallation complete."
}

