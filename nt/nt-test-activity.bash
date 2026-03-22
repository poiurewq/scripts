#!/usr/bin/env bash
# nt-test-activity.bash — tests for a/ar (activity summary)
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_ACTIVITY (array of test function names)

#####################################################################
# Tests — nt a: activity summary
#####################################################################

test_activity_no_docs() {
    nt_test__assert_output_contains "No indexed documents" "$NT_SCRIPT" a
}

test_activity_no_docs_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT" a
}

test_activity_shows_header() {
    nt_test__create_file "001-note.md"
    nt_test__assert_output_contains "Activity Summary" "$NT_SCRIPT" a
}

test_activity_shows_total() {
    nt_test__create_file "001-note.md"
    nt_test__create_file "002-note.md"
    nt_test__create_file "003-note.md"
    nt_test__assert_output_contains "Total: 3 documents" "$NT_SCRIPT" a
}

test_activity_counts_only_indexed() {
    # Non-indexed files should not be counted
    nt_test__create_file "001-note.md"
    nt_test__create_file "README.md"
    nt_test__create_file "random.txt"
    nt_test__assert_output_contains "Total: 1 documents" "$NT_SCRIPT" a
}

test_activity_shows_month_bar() {
    nt_test__create_file "001-note.md"
    # The output should contain a # bar character
    nt_test__assert_output_contains "#" "$NT_SCRIPT" a
}

#####################################################################
# Tests — nt ar: recursive activity
#####################################################################

test_activity_recursive_finds_subdirs() {
    mkdir -p "$NT_TEST_DIR/sub"
    nt_test__create_file "001-note.md"
    printf '' > "$NT_TEST_DIR/sub/002-note.md"
    nt_test__assert_output_contains "Total: 2 documents" "$NT_SCRIPT" ar
}

test_activity_non_recursive_ignores_subdirs() {
    mkdir -p "$NT_TEST_DIR/sub"
    nt_test__create_file "001-note.md"
    printf '' > "$NT_TEST_DIR/sub/002-note.md"
    nt_test__assert_output_contains "Total: 1 documents" "$NT_SCRIPT" a
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_ACTIVITY=(
    test_activity_no_docs
    test_activity_no_docs_exits_zero
    test_activity_shows_header
    test_activity_shows_total
    test_activity_counts_only_indexed
    test_activity_shows_month_bar
    test_activity_recursive_finds_subdirs
    test_activity_non_recursive_ignores_subdirs
)
