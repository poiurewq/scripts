#!/usr/bin/env bash
# nt-test-open.bash — tests for numeric open (nt <num>)
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_OPEN (array of test function names)

#####################################################################
# Tests — nt <num>: open by index
#####################################################################

test_open_single_index() {
    nt_test__create_file "003-note.md"
    nt_test__assert_output_contains "003-note.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 3
}

test_open_zero_padded_input() {
    nt_test__create_file "007-note.md"
    nt_test__assert_output_contains "007-note.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 007
}

test_open_unpadded_input() {
    nt_test__create_file "007-note.md"
    nt_test__assert_output_contains "007-note.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 7
}

test_open_missing_index_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" 99
}

test_open_missing_index_message() {
    nt_test__assert_output_contains "not found" "$NT_SCRIPT" 99
}

#####################################################################
# Tests — nt <num> <num>: open multiple
#####################################################################

test_open_multiple_indices() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "003-c.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1 3 2>&1)" || true
    if ! printf '%s' "$output" | grep -qF "001-a.md"; then
        printf 'FAIL: output should contain 001-a.md\n  actual: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 ))
        return 1
    fi
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    if ! printf '%s' "$output" | grep -qF "003-c.md"; then
        printf 'FAIL: output should contain 003-c.md\n  actual: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 ))
        return 1
    fi
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

#####################################################################
# Tests — nt <num> combined with R and t
#####################################################################

test_open_with_readme() {
    nt_test__create_file "001-note.md"
    nt_test__create_file "README.md" "# Readme"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1 R 2>&1)" || true
    if ! printf '%s' "$output" | grep -qF "001-note.md"; then
        printf 'FAIL: output should contain 001-note.md\n  actual: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 ))
        return 1
    fi
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

#####################################################################
# Tests — exit codes
#####################################################################

test_open_exits_zero() {
    nt_test__create_file "001.md"
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" 1
}

#####################################################################
# Tests — Phase 2: input validation
#####################################################################

test_open_index_zero_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" 0
}

test_open_error_to_stderr() {
    # Error for missing index should go to stderr, not stdout
    local stdout_only
    stdout_only="$("$NT_SCRIPT" 99 2>/dev/null)" || true
    if [ -n "$stdout_only" ]; then
        printf 'FAIL: error output appeared on stdout: %s\n' "$stdout_only"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 ))
        return 1
    fi
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_OPEN=(
    test_open_single_index
    test_open_zero_padded_input
    test_open_unpadded_input
    test_open_missing_index_fails
    test_open_missing_index_message
    test_open_multiple_indices
    test_open_with_readme
    test_open_exits_zero
    test_open_index_zero_fails
    test_open_error_to_stderr
)
