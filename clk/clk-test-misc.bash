#!/usr/bin/env bash
# clk-test-misc.bash — integration tests for alias, log, help
#
# Sourced by clk-test; do not run directly.
# Defines: CLK_TESTS_MISC (array of test function names)

#####################################################################
# Tests — clk alias
#####################################################################

test_alias_adds_to_rc() {
    # Create a fake shell rc file
    local rc_file="$CLK_TEST_DIR/.zshrc"
    : > "$rc_file"
    # Override HOME so alias writes to our test dir
    HOME="$CLK_TEST_DIR" SHELL="/bin/zsh" "$CLK_SCRIPT" alias >/dev/null 2>&1
    if ! grep -qF "alias c='clk'" "$rc_file"; then
        printf 'FAIL: alias line not found in %s\n' "$rc_file"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_alias_idempotent() {
    local rc_file="$CLK_TEST_DIR/.zshrc"
    : > "$rc_file"
    HOME="$CLK_TEST_DIR" SHELL="/bin/zsh" "$CLK_SCRIPT" alias >/dev/null 2>&1
    HOME="$CLK_TEST_DIR" SHELL="/bin/zsh" "$CLK_SCRIPT" alias >/dev/null 2>&1
    local count
    count="$(grep -cF "alias c='clk'" "$rc_file")"
    clk_test__assert_equals "1" "$count" "alias should only appear once"
}

test_alias_already_exists_message() {
    local rc_file="$CLK_TEST_DIR/.zshrc"
    printf "alias c='clk'\n" > "$rc_file"
    clk_test__assert_output_contains "already exists" \
        env HOME="$CLK_TEST_DIR" SHELL="/bin/zsh" "$CLK_SCRIPT" alias
}

test_alias_bash_rc() {
    local rc_file="$CLK_TEST_DIR/.bashrc"
    : > "$rc_file"
    HOME="$CLK_TEST_DIR" SHELL="/bin/bash" "$CLK_SCRIPT" alias >/dev/null 2>&1
    if ! grep -qF "alias c='clk'" "$rc_file"; then
        printf 'FAIL: alias line not found in %s\n' "$rc_file"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Tests — clk log
#####################################################################

test_log_opens_editor() {
    # Set VISUAL to a command that just prints the file path
    local output
    output="$(VISUAL="echo" "$CLK_SCRIPT" log 2>&1)"
    # Should have printed the path to clk.tsv
    if ! printf '%s' "$output" | grep -qF "clk.tsv"; then
        printf 'FAIL: log should invoke editor with clk.tsv path\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_log_respects_visual() {
    local output
    output="$(VISUAL="echo" EDITOR="should-not-use" "$CLK_SCRIPT" log 2>&1)"
    if ! printf '%s' "$output" | grep -qF "clk.tsv"; then
        printf 'FAIL: log should prefer VISUAL over EDITOR\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_log_falls_back_to_editor() {
    local output
    output="$(unset VISUAL; EDITOR="echo" "$CLK_SCRIPT" log 2>&1)"
    if ! printf '%s' "$output" | grep -qF "clk.tsv"; then
        printf 'FAIL: log should fall back to EDITOR when VISUAL is unset\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Tests — clk help
#####################################################################

test_help_shows_synopsis() {
    # help falls back to synopsis when man page not found
    local output
    output="$(MANPATH=/nonexistent "$CLK_SCRIPT" help 2>&1)" || true
    if ! printf '%s' "$output" | grep -qF "clk"; then
        printf 'FAIL: help should show something about clk\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_help_exit_zero() {
    clk_test__assert_exit 0 "$CLK_SCRIPT" help
}

#####################################################################
# Test registry
#####################################################################

CLK_TESTS_MISC=(
    test_alias_adds_to_rc
    test_alias_idempotent
    test_alias_already_exists_message
    test_alias_bash_rc
    test_log_opens_editor
    test_log_respects_visual
    test_log_falls_back_to_editor
    test_help_shows_synopsis
    test_help_exit_zero
)
