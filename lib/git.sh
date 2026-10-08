#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

# Git repository and submodule helpers.
# Requires common.sh and logging.sh.

_git_require_repository() {
    local repository="${1:-.}"
    shell_utils_command_exists git || { log_error "git was not found."; return 2; }
    git -C "$repository" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        log_error "Not a Git repository: $repository"
        return 2
    }
}

update_git_repository() {
    local repository="${1:-.}" remote="${2:-origin}" branch="${3:-}"
    _git_require_repository "$repository" || return

    if [ -n "$(git -C "$repository" status --porcelain)" ]; then
        log_warn "Repository has uncommitted changes: $repository"
    fi

    if [ -z "$branch" ]; then
        branch="$(git -C "$repository" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
    fi
    [ -n "$branch" ] || { log_error "Cannot update a detached HEAD without an explicit branch."; return 1; }

    log_info "Fetching $remote for repository: $repository"
    git -C "$repository" fetch --prune "$remote"
    log_info "Rebasing $branch onto $remote/$branch"
    git -C "$repository" pull --rebase "$remote" "$branch"
}

update_git_repositories() {
    [ "$#" -gt 0 ] || { log_error "Usage: update_git_repositories REPOSITORY..."; return 2; }
    local repository failed=0
    for repository in "$@"; do
        update_git_repository "$repository" || failed=1
    done
    return "$failed"
}

init_git_submodule() {
    local repository="${1:-.}" submodule_path="${2:-}"
    [ -n "$submodule_path" ] || { log_error "Usage: init_git_submodule REPOSITORY SUBMODULE_PATH"; return 2; }
    _git_require_repository "$repository" || return

    if ! git -C "$repository" config --file .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}' | grep -Fxq -- "$submodule_path"; then
        log_error "Unknown submodule path: $submodule_path"
        return 1
    fi

    log_info "Initialising submodule: $submodule_path"
    git -C "$repository" submodule update --init --recursive -- "$submodule_path"
}

list_git_submodules() {
    local repository="${1:-.}"
    _git_require_repository "$repository" || return
    [ -f "$repository/.gitmodules" ] || return 0
    git -C "$repository" config --file .gitmodules --get-regexp path 2>/dev/null | awk '{print $2}'
}
