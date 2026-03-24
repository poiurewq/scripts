#!/usr/bin/env bash
# nt-test-rename.bash — tests for r/rename, rl
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
    nt_test__assert_output_contains "renamed to" "$NT_SCRIPT" r 1 "updated"
}

test_rename_spaces_become_hyphens() {
    nt_test__create_file "001-note.md"
    "$NT_SCRIPT" r 1 "hello world" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-hello-world.md" \
        "spaces in rename title should become hyphens"
}

#####################################################################
# Tests — nt rename: long-form alias (Phase 3)
#####################################################################

test_rename_long_form_alias() {
    nt_test__create_file "004-old.md"
    "$NT_SCRIPT" rename 4 "fresh-title" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004-fresh-title.md" \
        "rename alias should rename doc"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004-old.md" \
        "original should be gone"
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
# Tests — Phase 2: input validation
#####################################################################

test_rename_index_zero_fails() {
    nt_test__create_file "001-note.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" r 0 "title"
}

test_rename_non_integer_index_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" r abc "title"
}

#####################################################################
# Tests — nt rl <title>: rename last document (Phase 3)
#####################################################################

test_rl_renames_last_doc() {
    nt_test__create_file "003-old-name.md"
    "$NT_SCRIPT" rl "new name" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003-new-name.md" \
        "rl should rename last doc"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/003-old-name.md" \
        "original should be gone after rl"
}

test_rl_renames_highest_index() {
    nt_test__create_file "001-first.md"
    nt_test__create_file "005-fifth.md"
    "$NT_SCRIPT" rl "updated" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/005-updated.md" \
        "rl should rename the highest-indexed doc, not the first"
}

test_rl_preserves_delimiter() {
    nt_test__create_file "002__old-name.md"
    "$NT_SCRIPT" rl "new name" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002__new-name.md" \
        "rl should preserve __ delimiter"
}

test_rl_preserves_extension() {
    nt_test__create_file "001-note.org"
    "$NT_SCRIPT" rl "renamed" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-renamed.org" \
        "rl should preserve .org extension"
}

test_rl_confirmation_message() {
    nt_test__create_file "001-old.md"
    nt_test__assert_output_contains "renamed to" "$NT_SCRIPT" rl "updated"
}

test_rl_spaces_become_hyphens() {
    nt_test__create_file "001-note.md"
    "$NT_SCRIPT" rl "hello world" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-hello-world.md" \
        "spaces in rl title should become hyphens"
}

test_rl_no_title_fails() {
    nt_test__create_file "001-note.md"
    nt_test__assert_exit 1 "$NT_SCRIPT" rl
}

test_rl_no_docs_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" rl "title"
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
    test_rename_long_form_alias
    test_rename_missing_args_fails
    test_rename_missing_title_fails
    test_rename_nonexistent_index_fails
    test_rename_nonexistent_index_message
    test_rename_index_zero_fails
    test_rename_non_integer_index_fails
    test_rl_renames_last_doc
    test_rl_renames_highest_index
    test_rl_preserves_delimiter
    test_rl_preserves_extension
    test_rl_confirmation_message
    test_rl_spaces_become_hyphens
    test_rl_no_title_fails
    test_rl_no_docs_fails
)
