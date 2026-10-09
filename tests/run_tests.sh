#!/usr/bin/env bash

# Author: Konstantin M.J. Winkel, M.Sc.

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$TEST_DIR/.." && pwd)"
# shellcheck source=../shell-utils.sh
source "$PROJECT_DIR/shell-utils.sh"

passed=0
failed=0

assert_success() {
    local name="$1"; shift
    if "$@"; then printf 'PASS: %s\n' "$name"; passed=$((passed + 1));
    else printf 'FAIL: %s\n' "$name"; failed=$((failed + 1)); fi
}

assert_failure() {
    local name="$1"; shift
    if "$@"; then printf 'FAIL: %s\n' "$name"; failed=$((failed + 1));
    else printf 'PASS: %s\n' "$name"; passed=$((passed + 1)); fi
}

capture_logs() {
    local output
    output="$(NO_COLOR=1 SHELL_UTILS_LOG_LEVEL=DEBUG log_info 'test message' 2>&1)"
    [[ "$output" =~ ^\[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\]\ \[INFO\]\ test\ message$ ]]
}

assert_success "timestamped logging" capture_logs
assert_success "command detection" shell_utils_command_exists bash
assert_failure "missing command detection" shell_utils_command_exists shell-utils-command-that-does-not-exist
assert_success "installed Python package detection" python_package_installed pip
assert_failure "missing Python package detection" python_package_installed shell-utils-package-that-does-not-exist

if command -v dpkg-query >/dev/null 2>&1; then
    assert_success "installed APT package detection" apt_package_installed bash
    assert_failure "missing APT package detection" apt_package_installed shell-utils-package-that-does-not-exist
fi

repo="$(mktemp -d)"
cleanup_root="$(mktemp -d "$PROJECT_DIR/../shell-utils-cleaning-test.XXXXXX")"
trap 'rm -rf "$repo" "$cleanup_root"' EXIT
git -C "$repo" init -q
assert_success "Git repository recognition" _git_require_repository "$repo"
assert_failure "unknown submodule rejected" init_git_submodule "$repo" missing/submodule
mkdir -p "$cleanup_root/allowed/__pycache__"
assert_success "cleanup accepts a descendant of the shell_utils parent" clean_python_cache "$cleanup_root"
assert_success "cleanup removes Python cache directories" test ! -d "$cleanup_root/allowed/__pycache__"
assert_failure "cleanup rejects the parent of the allowed tree" clean_python_cache "$PROJECT_DIR/../.."
printf '\nTests: %d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
