#!/usr/bin/env bash
# nt-test-renumber.bash — tests for rn/renumber
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_RENUMBER (array of test function names)

#####################################################################
# Tests — nt rn <n> <m>: basic renumbering
#####################################################################

test_renumber_single_file() {
    nt_test__create_file "003-note.md"
    "$NT_SCRIPT" rn 3 7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/007-note.md" \
        "rn 3 7 should rename 003 to 007"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/003-note.md" \
        "original 003 should be gone"
}

test_renumber_consecutive_run() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "004-b.md"
    nt_test__create_file "005-c.md"
    "$NT_SCRIPT" rn 3 10 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/010-a.md" "003 -> 010"
    nt_test__assert_file_exists "$NT_TEST_DIR/011-b.md" "004 -> 011"
    nt_test__assert_file_exists "$NT_TEST_DIR/012-c.md" "005 -> 012"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/003-a.md" "003 gone"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004-b.md" "004 gone"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/005-c.md" "005 gone"
}

test_renumber_stops_at_gap() {
    # 003, 004, (gap), 006 — only 003 and 004 should move
    nt_test__create_file "003-a.md"
    nt_test__create_file "004-b.md"
    nt_test__create_file "006-c.md"
    "$NT_SCRIPT" rn 3 10 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/010-a.md" "003 -> 010"
    nt_test__assert_file_exists "$NT_TEST_DIR/011-b.md" "004 -> 011"
    nt_test__assert_file_exists "$NT_TEST_DIR/006-c.md" "006 should be untouched"
}

test_renumber_downward() {
    nt_test__create_file "010-a.md"
    nt_test__create_file "011-b.md"
    "$NT_SCRIPT" rn 10 3 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003-a.md" "010 -> 003"
    nt_test__assert_file_exists "$NT_TEST_DIR/004-b.md" "011 -> 004"
}

test_renumber_preserves_content() {
    nt_test__create_file "001-note.md" "important content"
    "$NT_SCRIPT" rn 1 5 >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/005-note.md" "important content" \
        "rn should preserve file content"
}

test_renumber_output_shows_mapping() {
    nt_test__create_file "003-note.md"
    nt_test__assert_output_contains "->" "$NT_SCRIPT" rn 3 7
}

#####################################################################
# Tests — nt rn: collision detection
#####################################################################

test_renumber_collision_fails() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "007-occupied.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" rn 3 7
}

test_renumber_collision_message() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "007-occupied.md"
    nt_test__assert_output_contains "already occupied" "$NT_SCRIPT" rn 3 7
}

#####################################################################
# Tests — nt rn: error cases
#####################################################################

test_renumber_missing_args_fails() {
    nt_test__assert_exit 1 "$NT_SCRIPT" rn
}

test_renumber_missing_second_arg_fails() {
    nt_test__assert_exit 1 "$NT_SCRIPT" rn 3
}

test_renumber_same_index_exits_zero() {
    nt_test__create_file "003.md"
    nt_test__assert_exit 0 "$NT_SCRIPT" rn 3 3
}

test_renumber_nonexistent_start_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" rn 99 1
}

test_renumber_non_integer_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" rn abc 5
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_RENUMBER=(
    test_renumber_single_file
    test_renumber_consecutive_run
    test_renumber_stops_at_gap
    test_renumber_downward
    test_renumber_preserves_content
    test_renumber_output_shows_mapping
    test_renumber_collision_fails
    test_renumber_collision_message
    test_renumber_missing_args_fails
    test_renumber_missing_second_arg_fails
    test_renumber_same_index_exits_zero
    test_renumber_nonexistent_start_fails
    test_renumber_non_integer_fails
)
