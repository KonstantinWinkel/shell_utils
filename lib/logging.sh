#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

# Coloured, timestamped logging. Set NO_COLOR=1 to disable colours.
# Set SHELL_UTILS_LOG_LEVEL to DEBUG, INFO, WARN, or ERROR.

: "${SHELL_UTILS_LOG_LEVEL:=INFO}"

_shell_utils_level_number() {
    case "${1^^}" in
        DEBUG) printf '10\n' ;;
        INFO)  printf '20\n' ;;
        WARN|WARNING) printf '30\n' ;;
        ERROR) printf '40\n' ;;
        *) return 1 ;;
    esac
}

_shell_utils_should_log() {
    local requested configured
    requested="$(_shell_utils_level_number "$1")" || return 1
    configured="$(_shell_utils_level_number "$SHELL_UTILS_LOG_LEVEL")" || configured=20
    [ "$requested" -ge "$configured" ]
}

_shell_utils_colour_enabled() {
    [ -z "${NO_COLOR:-}" ] && [ -t 2 ]
}

_shell_utils_log() {
    local level="$1" colour="$2" message="$3" reset='' prefix=''
    _shell_utils_should_log "$level" || return 0

    if _shell_utils_colour_enabled; then
        prefix="${colour}"
        reset='\033[0m'
    fi

    printf '%b[%s] [%s] %s%b\n' \
        "$prefix" "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" "$reset" >&2
}

log_debug() { _shell_utils_log DEBUG '\033[0;36m' "$*"; }
log_info()  { _shell_utils_log INFO  '\033[0;32m' "$*"; }
log_warn()  { _shell_utils_log WARN  '\033[1;33m' "$*"; }
log_error() { _shell_utils_log ERROR '\033[0;31m' "$*"; }
