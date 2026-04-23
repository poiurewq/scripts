#!/usr/bin/env bash
# nt-test-misc.bash — tests for help, R, t, editor resolution, usage, unknown commands
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
# Tests — nt h / nt help: help (Phase 3: -h removed)
#####################################################################

test_help_h() {
    nt_test__assert_output_contains "nt" "$NT_SCRIPT" h
}

test_help_long_form() {
    nt_test__assert_output_contains "nt" "$NT_SCRIPT" help
}

test_help_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT" h
}

test_help_long_form_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT" help
}

test_help_dash_h_works() {
    # -h is the hyphen-prefixed form of help; it should print help
    nt_test__assert_exit 0 "$NT_SCRIPT" -h
}

test_help_double_dash_works() {
    nt_test__assert_output_contains "nt" "$NT_SCRIPT" --help
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

test_readme_creates_if_missing() {
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" R
    nt_test__assert_file_exists "$NT_TEST_DIR/README.md" \
        "R should create README.md if missing"
}

test_readme_hyphen_form() {
    nt_test__create_file "README.md" "# readme"
    nt_test__assert_output_contains "README.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" -R
}

#####################################################################
# Tests — nt C: open CLAUDE.md
#####################################################################

test_claude_opens() {
    nt_test__create_file "CLAUDE.md" "# My CLAUDE.md"
    nt_test__assert_output_contains "CLAUDE.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" C
}

test_claude_creates_if_missing() {
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" C
    nt_test__assert_file_exists "$NT_TEST_DIR/CLAUDE.md" \
        "C should create CLAUDE.md if missing"
}

test_claude_hyphen_form() {
    nt_test__create_file "CLAUDE.md" "# claude"
    nt_test__assert_output_contains "CLAUDE.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" -C
}

#####################################################################
# Tests — nt t: open template
#####################################################################

test_template_opens() {
    nt_test__create_file "nt_template.md" "template"
    nt_test__assert_output_contains ".nt/template.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" t
}

test_template_creates_if_missing() {
    env NT_EDITOR="true" "$NT_SCRIPT" t >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/.nt/template.md" \
        "t should create .nt/template.md if missing"
}

test_template_not_found_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT" t
}

test_template_hyphen_form() {
    nt_test__create_file "nt_template.md" "template"
    nt_test__assert_output_contains ".nt/template.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" -t
}

test_template_too_many_fails() {
    : > "$NT_TEST_DIR/nt_template.md"
    : > "$NT_TEST_DIR/nt_template.txt"
    nt_test__assert_exit 5 "$NT_SCRIPT" t
}

#####################################################################
# Tests — editor resolution (Phase 3: e command removed)
#
# Resolution order: NT_EDITOR > VISUAL > EDITOR > vim
#####################################################################

test_editor_nt_editor_wins() {
    # NT_EDITOR takes priority over VISUAL and EDITOR
    nt_test__create_file "001.md"
    nt_test__assert_output_contains "001.md" \
        env NT_EDITOR="echo" VISUAL="true" EDITOR="true" "$NT_SCRIPT" 1
}

test_editor_visual_fallback() {
    # When NT_EDITOR is unset, VISUAL is used
    nt_test__create_file "001.md"
    nt_test__assert_output_contains "001.md" \
        env -u NT_EDITOR VISUAL="echo" EDITOR="true" "$NT_SCRIPT" 1
}

test_editor_editor_fallback() {
    # When NT_EDITOR and VISUAL are unset, EDITOR is used
    nt_test__create_file "001.md"
    nt_test__assert_output_contains "001.md" \
        env -u NT_EDITOR -u VISUAL EDITOR="echo" "$NT_SCRIPT" 1
}

test_editor_e_command_removed() {
    # The 'e' subcommand was removed in Phase 3
    nt_test__assert_exit 2 "$NT_SCRIPT" e vim
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
# Tests — long-form aliases (Phase 3)
#####################################################################

test_alias_new() {
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" new
}

test_alias_reindex() {
    nt_test__create_file "003-note.md"
    nt_test__assert_exit 0 "$NT_SCRIPT" reindex 3 3
}

test_alias_activity() {
    nt_test__create_file "001-note.md"
    nt_test__assert_output_contains "Activity Summary" "$NT_SCRIPT" activity
}

test_alias_activity_recursive() {
    nt_test__create_file "001-note.md"
    nt_test__assert_output_contains "Activity Summary" "$NT_SCRIPT" activity-recursive
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
    test_help_long_form
    test_help_exits_zero
    test_help_long_form_exits_zero
    test_help_dash_h_works
    test_help_double_dash_works
    test_readme_opens
    test_readme_case_insensitive
    test_readme_creates_if_missing
    test_readme_hyphen_form
    test_claude_opens
    test_claude_creates_if_missing
    test_claude_hyphen_form
    test_template_opens
    test_template_creates_if_missing
    test_template_not_found_exits_zero
    test_template_hyphen_form
    test_template_too_many_fails
    test_editor_nt_editor_wins
    test_editor_visual_fallback
    test_editor_editor_fallback
    test_editor_e_command_removed
    test_nt_editor_default_vim
    test_nt_editor_respects_env
    test_alias_new
    test_alias_reindex
    test_alias_activity
    test_alias_activity_recursive
    test_unknown_command_fails
    test_unknown_command_message
)
