#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

#. Source this file from project scripts.

if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SHELL_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    printf '%s\n' "shell-utils requires Bash." >&2
    return 1 2>/dev/null || exit 1
fi

# shellcheck source=lib/common.sh
source "$SHELL_UTILS_DIR/lib/common.sh"
# shellcheck source=lib/logging.sh
source "$SHELL_UTILS_DIR/lib/logging.sh"
# shellcheck source=lib/packages.sh
source "$SHELL_UTILS_DIR/lib/packages.sh"
# shellcheck source=lib/git.sh
source "$SHELL_UTILS_DIR/lib/git.sh"
