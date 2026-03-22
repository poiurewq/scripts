#!/usr/bin/env bash
# nt-test-last.bash — tests for l/last (open last document)
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_LAST (array of test function names)

#####################################################################
# Tests — nt l: open last doc
#####################################################################

test_last_opens_last_doc() {
    # NT_EDITOR=echo so we can see which file it tries to open
    nt_test__create_file "001-first.md"
    nt_test__create_file "003-third.md"
    nt_test__assert_output_contains "003-third.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l
}

test_last_no_docs_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" l
}

test_last_no_docs_message() {
    nt_test__assert_output_contains "No indexed document" \
        "$NT_SCRIPT" l
}

#####################################################################
# Tests — nt l n: print last index number
#####################################################################

test_last_n_prints_number() {
    nt_test__create_file "007-note.md"
    nt_test__assert_output_equals "7" "$NT_SCRIPT" l n
}

test_last_n_prints_highest() {
    nt_test__create_file "003.md"
    nt_test__create_file "010-note.md"
    nt_test__assert_output_equals "10" "$NT_SCRIPT" l n
}

test_last_n_no_docs() {
    nt_test__assert_exit 2 "$NT_SCRIPT" l n
}

#####################################################################
# Tests — nt l: with title (rename — current behavior, pre-Phase 3)
#
# NOTE: After Phase 3, `l <title>` will be removed. These tests
# document the current behavior and should be replaced with `rl`
# tests when Phase 3 lands.
#####################################################################

test_last_rename_with_title() {
    nt_test__create_file "001-old-name.md"
    "$NT_SCRIPT" l "new name" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-new-name.md" \
        "l with title should rename last doc"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/001-old-name.md" \
        "original file should be gone after rename"
}

test_last_rename_preserves_delimiter() {
    nt_test__create_file "001__old-name.md"
    "$NT_SCRIPT" l "new name" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001__new-name.md" \
        "l rename should preserve __ delimiter"
}

test_last_rename_confirmation_message() {
    nt_test__create_file "001-old.md"
    nt_test__assert_output_contains "renamed to" "$NT_SCRIPT" l "new"
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_LAST=(
    test_last_opens_last_doc
    test_last_no_docs_fails
    test_last_no_docs_message
    test_last_n_prints_number
    test_last_n_prints_highest
    test_last_n_no_docs
    test_last_rename_with_title
    test_last_rename_preserves_delimiter
    test_last_rename_confirmation_message
)
