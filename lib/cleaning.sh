#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

# Cleans up certain aspects of projects

clean_python_cache() {
    [ "$#" -eq 1 ] && [ -n "$1" ] || {
        log_error "Usage: clean_python_cache ROOT_DIRECTORY"
        return 2
    }
    local allowed_root root count
    [ -d "$1" ] || {
        log_error "Cleanup root is not an existing directory: $1"
        return 2
    }
    allowed_root="$(cd -- "$SHELL_UTILS_DIR/.." 2>/dev/null && pwd -P)" || {
        log_error "Unable to resolve the allowed cleanup root."
        return 2
    }
    root="$(cd -- "$1" 2>/dev/null && pwd -P)" || {
        log_error "Unable to resolve cleanup root: $1"
        return 2
    }
    case "$root" in
        "$allowed_root"|"$allowed_root"/*)
            ;;
        *)
            log_error "Cleanup root must be the directory containing shell_utils or one of its descendants: $root"
            return 2
            ;;
    esac
    log_info "Cleaning __pycache__ folders starting from $root"
    count="$(find "$root" -type d -name "__pycache__" -print 2>/dev/null | wc -l)" || {
        log_error "Failed to search for __pycache__ folders under: $root"
        return 1
    }
    if [ "$count" -eq 0 ]; then
        log_info "No __pycache__ folders found."
        return 0
    fi
    log_info "Found $count __pycache__ folder(s). Deleting..."
    if ! find "$root" -type d -name "__pycache__" -exec rm -rf -- {} +; then
        log_error "Cleanup of __pycache__ failed."
        return 1
    fi
    log_info "Cleanup of __pycache__ complete."
}
