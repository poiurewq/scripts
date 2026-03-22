#!/usr/bin/env bash
# nt-test-rename.bash — tests for r/rename
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_RENAME (array of test function names)

#####################################################################
# Tests — nt r <num> <title>: rename by index
#####################################################################

test_rename_basic() {
    nt_test__create_file "003-old-title.md"
    "$NT_SCRIPT" r 3 "new title" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003-new-title.md" \
        "r should rename doc 003 to new title"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/003-old-title.md" \
        "original file should be gone after rename"
}

test_rename_preserves_extension() {
    nt_test__create_file "005-note.org"
    "$NT_SCRIPT" r 5 "renamed" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/005-renamed.org" \
        "r should preserve .org extension"
}

test_rename_preserves_underscore_delimiter() {
    nt_test__create_file "002__note.md"
    "$NT_SCRIPT" r 2 "renamed" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002__renamed.md" \
        "r should preserve __ delimiter"
}

test_rename_preserves_content() {
    nt_test__create_file "001-note.md" "important content"
    "$NT_SCRIPT" r 1 "renamed" >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/001-renamed.md" "important content" \
        "r should preserve file content"
}

test_rename_confirmation_message() {
    nt_test__create_file "001-old.md"
    nt_test__assert_output_contains "renamed to" "$NT_SCRIPT" r 1 "new"
}

test_rename_spaces_become_hyphens() {
    nt_test__create_file "001-note.md"
    "$NT_SCRIPT" r 1 "hello world" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-hello-world.md" \
        "spaces in rename title should become hyphens"
}

#####################################################################
# Tests — nt r: error cases
#####################################################################

test_rename_missing_args_fails() {
    # r with no num or title
    nt_test__assert_exit 1 "$NT_SCRIPT" r
}

test_rename_missing_title_fails() {
    # r with num but no title
    nt_test__assert_exit 1 "$NT_SCRIPT" r 5
}

test_rename_nonexistent_index_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" r 99 "title"
}

test_rename_nonexistent_index_message() {
    nt_test__assert_output_contains "not found" "$NT_SCRIPT" r 99 "title"
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_RENAME=(
    test_rename_basic
    test_rename_preserves_extension
    test_rename_preserves_underscore_delimiter
    test_rename_preserves_content
    test_rename_confirmation_message
    test_rename_spaces_become_hyphens
    test_rename_missing_args_fails
    test_rename_missing_title_fails
    test_rename_nonexistent_index_fails
    test_rename_nonexistent_index_message
)
