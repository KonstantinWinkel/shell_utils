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

_git_validate_remote_url() {
    local repository="$1" remote="$2" url
    url="$(git -C "$repository" remote get-url -- "$remote" 2>/dev/null)" || return 1
    case "$url" in
        http://*|https://*|git://*|git@*|ssh://*)
            ;;
        ext::*)
            log_error "Remote with ext:: protocol rejected: $remote"
            return 1
            ;;
        file://*)
            if [ "${SHELL_UTILS_GIT_STRICT:-0}" = "1" ]; then
                log_error "Remote with file:// protocol rejected in strict mode: $remote"
                return 1
            fi
            log_warn "Remote with file:// protocol detected: $remote"
            if [ -t 0 ]; then
                read -r -p "Continue? [y/N] " response
                case "$response" in
                    [Yy]|[Yy][Ee][Ss]) ;;
                    *) return 2 ;;
                esac
            else
                log_error "Remote with file:// protocol rejected on non-interactive terminals: $remote"
                return 1
            fi
            ;;
        *)
            if [ "${SHELL_UTILS_GIT_STRICT:-0}" = "1" ]; then
                log_error "Remote with unknown protocol rejected in strict mode: $remote"
                return 1
            fi
            log_warn "Remote with unknown protocol detected: $remote"
            if [ -t 0 ]; then
                read -r -p "Continue? [y/N] " response
                case "$response" in
                    [Yy]|[Yy][Ee][Ss]) ;;
                    *) return 2 ;;
                esac
            else
                log_error "Remote with unknown protocol rejected on non-interactive terminals: $remote"
                return 1
            fi
            ;;
    esac
}

update_git_repository() {
    local repository="${1:-.}" remote="${2:-origin}" branch="${3:-}"
    _git_require_repository "$repository" || return

    case "$remote" in
        -*) log_error "Git remote must not begin with '-': $remote"; return 2 ;;
    esac
    case "$branch" in
        -*) log_error "Git branch must not begin with '-': $branch"; return 2 ;;
    esac

    if ! git -C "$repository" remote get-url -- "$remote" >/dev/null 2>&1; then
        log_error "Unknown Git remote: $remote"
        return 2
    fi

    _git_validate_remote_url "$repository" "$remote" || return

    if [ -n "$(git -C "$repository" status --porcelain)" ]; then
        log_warn "Repository has uncommitted changes: $repository"
    fi

    if [ -z "$branch" ]; then
        branch="$(git -C "$repository" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
    fi
    [ -n "$branch" ] || { log_error "Cannot update a detached HEAD without an explicit branch."; return 1; }

    case "$branch" in
        -*) log_error "Git branch must not begin with '-': $branch"; return 2 ;;
    esac
    if ! git check-ref-format --branch "$branch" >/dev/null 2>&1; then
        log_error "Invalid Git branch name: $branch"
        return 2
    fi

    log_info "Fetching $remote for repository: $repository"
    git -C "$repository" fetch --prune -- "$remote" || return
    log_info "Rebasing $branch onto $remote/$branch"
    git -C "$repository" pull --rebase -- "$remote" "$branch"
}

update_git_repositories() {
    [ "$#" -gt 0 ] || { log_error "Usage: update_git_repositories REPOSITORY..."; return 2; }
    local repository failed=0
    for repository in "$@"; do
        update_git_repository "$repository" || failed=1
    done
    return "$failed"
}

_git_list_submodule_paths() {
    local repository="$1" record
    while IFS= read -r -d '' record; do
        printf '%s\n' "${record#*$'\n'}"
    done < <(
        git -C "$repository" config --null --file .gitmodules \
            --get-regexp '^submodule\..*\.path$' 2>/dev/null
    )
}

init_git_submodule() {
    local repository="${1:-.}" submodule_path="${2:-}" known_path
    [ -n "$submodule_path" ] || { log_error "Usage: init_git_submodule REPOSITORY SUBMODULE_PATH"; return 2; }
    _git_require_repository "$repository" || return
    while IFS= read -r known_path; do
        if [ "$known_path" = "$submodule_path" ]; then
            log_info "Initialising submodule: $submodule_path"
            git -C "$repository" submodule update --init --recursive -- "$submodule_path"
            return $?
        fi
    done < <(_git_list_submodule_paths "$repository")
    log_error "Unknown submodule path: $submodule_path"
    return 1
}

list_git_submodules() {
    local repository="${1:-.}"
    _git_require_repository "$repository" || return
    [ -f "$repository/.gitmodules" ] || return 0
    _git_list_submodule_paths "$repository"
}
