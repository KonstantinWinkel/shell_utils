#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

# Cleans up certain aspects of projects

clean_python_cache() {
    log_info "Cleaning __pycache__ folders starting from $1"

    count =$(find "$1" -type d -name "__pycache__" | wc -l)

    if ["$count" -eq 0]; then
        log_info "No __pycache__ folders found."
    else
        log_info "Found $count __pycache__ folder(s). Deleting..."
        find "$1" -type d -name "__pycache__" -exec rm -rf {} +
        log_info "Cleanup of __pycache__ complete."
    fi
}