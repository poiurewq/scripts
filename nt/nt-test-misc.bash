#!/usr/bin/env bash
# nt-test-misc.bash — tests for help, R, t, editor, usage, unknown commands
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_MISC (array of test function names)

#####################################################################
# Tests — nt (no args): usage
#####################################################################

test_usage_no_args() {
    nt_test__assert_output_contains "usage:" "$NT_SCRIPT"
}

test_usage_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT"
}

#####################################################################
# Tests — nt h / nt -h: help
#####################################################################

test_help_h() {
    nt_test__assert_output_contains "nt" "$NT_SCRIPT" h
}

test_help_dash_h() {
    nt_test__assert_output_contains "nt" "$NT_SCRIPT" -h
}

test_help_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT" h
}

#####################################################################
# Tests — nt R: open README
#####################################################################

test_readme_opens() {
    nt_test__create_file "README.md" "# My README"
    nt_test__assert_output_contains "README.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" R
}

test_readme_case_insensitive() {
    # find . -iname readme.md should match Readme.md
    nt_test__create_file "Readme.md" "# Readme"
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" R
}

test_readme_not_found_fails() {
    nt_test__assert_exit 4 "$NT_SCRIPT" R
}

test_readme_not_found_message() {
    nt_test__assert_output_contains "No README.md" "$NT_SCRIPT" R
}

#####################################################################
# Tests — nt t: open template
#####################################################################

test_template_opens() {
    nt_test__create_file "nt_template.md" "template"
    nt_test__assert_output_contains "nt_template.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" t
}

test_template_not_found() {
    nt_test__assert_output_contains "No nt template" "$NT_SCRIPT" t
}

test_template_not_found_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT" t
}

test_template_too_many_fails() {
    : > "$NT_TEST_DIR/nt_template.md"
    : > "$NT_TEST_DIR/nt_template.txt"
    nt_test__assert_exit 5 "$NT_SCRIPT" t
}

#####################################################################
# Tests — nt e: set editor (current behavior, pre-Phase 3)
#
# NOTE: After Phase 3, the `e` command will be removed entirely.
# These tests document current behavior.
#####################################################################

test_editor_no_arg_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" e
}

test_editor_no_arg_message() {
    nt_test__assert_output_contains "No editor given" "$NT_SCRIPT" e
}

test_editor_clipboard_or_manual_message() {
    # Should mention either clipboard or the export command
    local output
    output="$("$NT_SCRIPT" e vim 2>&1)" || true
    if printf '%s' "$output" | grep -qF "clipboard"; then
        NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    elif printf '%s' "$output" | grep -qF "export"; then
        NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    else
        printf 'FAIL: e should mention clipboard or export command\n  actual: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 ))
        return 1
    fi
}

#####################################################################
# Tests — NT_EDITOR environment variable
#####################################################################

test_nt_editor_default_vim() {
    # Without NT_EDITOR set, default is vim; just check it doesn't error
    # on an existing file (using 'true' as editor to avoid actually opening vim)
    nt_test__create_file "001.md"
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" 1
}

test_nt_editor_respects_env() {
    nt_test__create_file "001.md"
    nt_test__assert_output_contains "001.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 1
}

#####################################################################
# Tests — unknown command
#####################################################################

test_unknown_command_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" zzz
}

test_unknown_command_message() {
    nt_test__assert_output_contains "Unknown option" "$NT_SCRIPT" zzz
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_MISC=(
    test_usage_no_args
    test_usage_exits_zero
    test_help_h
    test_help_dash_h
    test_help_exits_zero
    test_readme_opens
    test_readme_case_insensitive
    test_readme_not_found_fails
    test_readme_not_found_message
    test_template_opens
    test_template_not_found
    test_template_not_found_exits_zero
    test_template_too_many_fails
    test_editor_no_arg_fails
    test_editor_no_arg_message
    test_editor_clipboard_or_manual_message
    test_nt_editor_default_vim
    test_nt_editor_respects_env
    test_unknown_command_fails
    test_unknown_command_message
)
