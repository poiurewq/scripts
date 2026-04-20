#!/usr/bin/env bash
# nt-test-reindex.bash — tests for ri/reindex (single-file and range forms)
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_REINDEX (array of test function names)

#####################################################################
# Tests — nt ri N M: single-file reindex
#####################################################################

test_reindex_basic() {
    nt_test__create_file "003-old-title.md"
    "$NT_SCRIPT" ri 3 7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/007-old-title.md" \
        "ri should reindex doc 003 to 007"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/003-old-title.md" \
        "original file should be gone after reindex"
}

test_reindex_preserves_extension() {
    nt_test__create_file "005-note.org"
    "$NT_SCRIPT" ri 5 2 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002-note.org" \
        "ri should preserve .org extension"
}

test_reindex_preserves_underscore_delimiter() {
    nt_test__create_file "002__note.md"
    "$NT_SCRIPT" ri 2 9 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/009__note.md" \
        "ri should preserve __ delimiter"
}

test_reindex_preserves_content() {
    nt_test__create_file "001-note.md" "important content"
    "$NT_SCRIPT" ri 1 5 >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/005-note.md" "important content" \
        "ri should preserve file content"
}

test_reindex_confirmation_message() {
    nt_test__create_file "001-old.md"
    nt_test__assert_output_contains "reindexed to" "$NT_SCRIPT" ri 1 5
}

test_reindex_can_change_depth() {
    nt_test__create_file "003-note.md"
    "$NT_SCRIPT" ri 3 1.5 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001.005-note.md" \
        "ri should allow depth change (flat to hierarchical)"
}

test_reindex_hierarchical_to_flat() {
    nt_test__create_file "001.002-sub.md"
    "$NT_SCRIPT" ri 1.2 7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/007-sub.md" \
        "ri should allow depth change (hierarchical to flat)"
}

test_reindex_same_index_noop() {
    nt_test__create_file "003-note.md"
    nt_test__assert_output_contains "Nothing to reindex" "$NT_SCRIPT" ri 3 3
    nt_test__assert_file_exists "$NT_TEST_DIR/003-note.md" \
        "file should remain unchanged when source == target"
}

test_reindex_source_not_found_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 99 5
}

test_reindex_source_not_found_message() {
    nt_test__assert_output_contains "not found" "$NT_SCRIPT" ri 99 5
}

test_reindex_target_occupied_fails() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "005-b.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 1 5
}

test_reindex_target_occupied_message() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "005-b.md"
    nt_test__assert_output_contains "already exists" "$NT_SCRIPT" ri 1 5
}

test_reindex_missing_args_fails() {
    nt_test__assert_exit 1 "$NT_SCRIPT" ri
}

test_reindex_missing_second_arg_fails() {
    nt_test__assert_exit 1 "$NT_SCRIPT" ri 1
}

test_reindex_invalid_index_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" ri abc 5
}

#####################################################################
# Tests — nt ri N-M A-B: range reindex
#####################################################################

test_reindex_range_basic() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "002-b.md"
    nt_test__create_file "003-c.md"
    "$NT_SCRIPT" ri 1-3 5-7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/005-a.md" "ri range: 001 -> 005"
    nt_test__assert_file_exists "$NT_TEST_DIR/006-b.md" "ri range: 002 -> 006"
    nt_test__assert_file_exists "$NT_TEST_DIR/007-c.md" "ri range: 003 -> 007"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/001-a.md" "original 001 should be gone"
}

test_reindex_range_hierarchical_source() {
    nt_test__create_file "003.001-x.md"
    nt_test__create_file "003.002-y.md"
    nt_test__create_file "003.003-z.md"
    "$NT_SCRIPT" ri 3.1-3.3 3.5-3.7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003.005-x.md" "ri range: 3.1 -> 3.5"
    nt_test__assert_file_exists "$NT_TEST_DIR/003.006-y.md" "ri range: 3.2 -> 3.6"
    nt_test__assert_file_exists "$NT_TEST_DIR/003.007-z.md" "ri range: 3.3 -> 3.7"
}

test_reindex_range_cross_depth() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "002-b.md"
    nt_test__create_file "003-c.md"
    "$NT_SCRIPT" ri 1-3 3.5-3.7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003.005-a.md" "cross-depth: 001 -> 003.005"
    nt_test__assert_file_exists "$NT_TEST_DIR/003.006-b.md" "cross-depth: 002 -> 003.006"
    nt_test__assert_file_exists "$NT_TEST_DIR/003.007-c.md" "cross-depth: 003 -> 003.007"
}

test_reindex_range_overlapping_forward_shift() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "002-b.md"
    nt_test__create_file "003-c.md"
    "$NT_SCRIPT" ri 1-3 2-4 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002-a.md" "overlap shift: 001 -> 002"
    nt_test__assert_file_exists "$NT_TEST_DIR/003-b.md" "overlap shift: 002 -> 003"
    nt_test__assert_file_exists "$NT_TEST_DIR/004-c.md" "overlap shift: 003 -> 004"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/001-a.md" "original 001 gone"
}

test_reindex_range_preserves_extension() {
    nt_test__create_file "001-a.org"
    nt_test__create_file "002-b.org"
    "$NT_SCRIPT" ri 1-2 5-6 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/005-a.org" "ri range preserves extension"
    nt_test__assert_file_exists "$NT_TEST_DIR/006-b.org" "ri range preserves extension"
}

test_reindex_range_skips_missing_source() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "003-c.md"
    "$NT_SCRIPT" ri 1-3 5-7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/005-a.md" "001 -> 005"
    nt_test__assert_file_exists "$NT_TEST_DIR/007-c.md" "003 -> 007"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/006-b.md" "002 was missing, 006 should not exist"
}

test_reindex_range_same_noop() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "002-b.md"
    nt_test__assert_output_contains "Nothing to reindex" "$NT_SCRIPT" ri 1-2 1-2
}

test_reindex_range_target_occupied_fails() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "005-blocker.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 1-3 5-7
}

test_reindex_range_count_mismatch_fails() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "002-b.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 1-2 5-8
}

test_reindex_range_count_mismatch_message() {
    nt_test__create_file "001-a.md"
    nt_test__assert_output_contains "same number of indices" "$NT_SCRIPT" ri 1-2 5-8
}

test_reindex_range_mixed_depth_source_fails() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "001.001-b.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 1-1.1 5-5.1
}

test_reindex_range_different_parent_fails() {
    nt_test__create_file "003.001-a.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 3.1-4.1 5.1-6.1
}

test_reindex_range_different_parent_message() {
    nt_test__create_file "003.001-a.md"
    nt_test__assert_output_contains "same parent" "$NT_SCRIPT" ri 3.1-4.1 5.1-6.1
}

test_reindex_range_mixed_forms_fails() {
    nt_test__create_file "001-a.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 1-3 5
}

# Regression: range reindex used 2>/dev/null on find_doc_by_index, making
# [[ -t 2 ]] false and causing multi-match sources to silently skip instead
# of surfacing the ambiguity.
test_reindex_range_multi_match_source_not_silent() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "003-b.md"
    nt_test__assert_output_contains "Multiple files" "$NT_SCRIPT" ri 3-3 7-7
}

test_reindex_range_multi_match_source_continues_other_sources() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "003-b.md"
    nt_test__create_file "005-x.md"
    "$NT_SCRIPT" ri 3-5 7-9 >/dev/null 2>&1 || true
    nt_test__assert_file_exists "$NT_TEST_DIR/009-x.md" \
        "005 should be reindexed despite multi-match on 003"
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_REINDEX=(
    test_reindex_basic
    test_reindex_preserves_extension
    test_reindex_preserves_underscore_delimiter
    test_reindex_preserves_content
    test_reindex_confirmation_message
    test_reindex_can_change_depth
    test_reindex_hierarchical_to_flat
    test_reindex_same_index_noop
    test_reindex_source_not_found_fails
    test_reindex_source_not_found_message
    test_reindex_target_occupied_fails
    test_reindex_target_occupied_message
    test_reindex_missing_args_fails
    test_reindex_missing_second_arg_fails
    test_reindex_invalid_index_fails
    test_reindex_range_basic
    test_reindex_range_hierarchical_source
    test_reindex_range_cross_depth
    test_reindex_range_overlapping_forward_shift
    test_reindex_range_preserves_extension
    test_reindex_range_skips_missing_source
    test_reindex_range_same_noop
    test_reindex_range_target_occupied_fails
    test_reindex_range_count_mismatch_fails
    test_reindex_range_count_mismatch_message
    test_reindex_range_mixed_depth_source_fails
    test_reindex_range_different_parent_fails
    test_reindex_range_different_parent_message
    test_reindex_range_mixed_forms_fails
    test_reindex_range_multi_match_source_not_silent
    test_reindex_range_multi_match_source_continues_other_sources
)
