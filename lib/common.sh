#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

# Common helpers for shell-utils. This file is intended to be sourced.

shell_utils_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

shell_utils_is_root() {
    [ "$(id -u)" -eq 0 ]
}

shell_utils_sudo_command() {
    if shell_utils_is_root; then
        printf '%s\n' ""
    elif shell_utils_command_exists sudo; then
        printf '%s\n' "sudo"
    else
        return 1
    fi
}
