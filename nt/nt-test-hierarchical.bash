#!/usr/bin/env bash
# nt-test-hierarchical.bash — tests for Phase 4 hierarchical index support
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_HIERARCHICAL (array of test function names)

#####################################################################
# Tests — find_doc_by_index: hierarchical indices
#####################################################################

test_hier_open_simple_still_works() {
    nt_test__create_file "003-note.md"
    nt_test__assert_output_contains "003-note.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 3
}

test_hier_open_by_hierarchical_index() {
    nt_test__create_file "004.7-sub-note.md"
    nt_test__assert_output_contains "004.7-sub-note.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 4.7
}

test_hier_open_deep_hierarchical_index() {
    nt_test__create_file "004.7.10-deep.md"
    nt_test__assert_output_contains "004.7.10-deep.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 4.7.10
}

test_hier_open_does_not_match_wrong_index() {
    # 004.7 should NOT match 004.70-other.md
    nt_test__create_file "004.70-other.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" 4.7
}

test_hier_open_no_title_variant() {
    # 004.7.md — hierarchical index with no title
    nt_test__create_file "004.7.md"
    nt_test__assert_output_contains "004.7.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 4.7
}

#####################################################################
# Tests — last_indexed_doc: hierarchical ordering
#####################################################################

test_hier_last_flat_wins_over_sub() {
    # 004 > 003.9 (cross-depth: 004 > 003.*)
    nt_test__create_file "003.9-sub.md"
    nt_test__create_file "004-main.md"
    nt_test__assert_output_contains "004-main.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l
}

test_hier_last_sub_within_same_parent() {
    # 003.10 > 003.9 (numeric, not lexicographic)
    nt_test__create_file "003.9-sub.md"
    nt_test__create_file "003.10-sub.md"
    nt_test__assert_output_contains "003.10-sub.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l
}

test_hier_last_mixed_flat_and_sub() {
    # 004.1 > 004 (sub-index follows parent)
    nt_test__create_file "003.md"
    nt_test__create_file "004.md"
    nt_test__create_file "004.1-sub.md"
    nt_test__assert_output_contains "004.1-sub.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l
}

test_hier_last_index_hierarchical() {
    # li should print the full hierarchical index (stripped of leading zeros)
    nt_test__create_file "004.7-note.md"
    nt_test__create_file "004.10-later.md"
    nt_test__assert_output_equals "4.10" "$NT_SCRIPT" li
}

test_hier_last_index_flat_unchanged() {
    nt_test__create_file "007-note.md"
    nt_test__assert_output_equals "7" "$NT_SCRIPT" li
}

#####################################################################
# Tests — cmd_new: auto-increment from hierarchical last
#####################################################################

test_hier_new_increments_from_flat() {
    nt_test__create_file "003.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.md" \
        "n after flat 003 should create 004"
}

test_hier_new_increments_last_component_of_hierarchical() {
    # Last is 004.7; next should be 004.8
    nt_test__create_file "003.md"
    nt_test__create_file "004.7-note.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.8.md" \
        "n after 004.7 should create 004.8"
}

test_hier_new_increments_carry_at_last_component() {
    # Last is 004.9; next should be 004.10 (no carry to parent)
    nt_test__create_file "004.9-note.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.10.md" \
        "n after 004.9 should create 004.10 (not 005)"
}

test_hier_new_with_title_after_hierarchical() {
    nt_test__create_file "004.7-note.md"
    "$NT_SCRIPT" n "sub note" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.8-sub-note.md" \
        "n with title after 004.7 should create 004.8-sub-note"
}

test_hier_new_inherits_delimiter_from_hierarchical() {
    nt_test__create_file "004.7__old.md"
    "$NT_SCRIPT" n "new" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.8__new.md" \
        "n should inherit __ delimiter from hierarchical last doc"
}

#####################################################################
# Tests — get_delimiter / get_extension with hierarchical filenames
#####################################################################

test_hier_delimiter_hyphen_in_hierarchical() {
    # Verifies delimiter detection works for hierarchical filenames
    nt_test__create_file "004.7-old-title.md"
    "$NT_SCRIPT" r 4.7 "new title" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.7-new-title.md" \
        "rename should preserve - delimiter in hierarchical filename"
}

test_hier_delimiter_underscore_in_hierarchical() {
    nt_test__create_file "004.7__old.md"
    "$NT_SCRIPT" r 4.7 "updated" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.7__updated.md" \
        "rename should preserve __ delimiter in hierarchical filename"
}

test_hier_extension_preserved_in_hierarchical() {
    nt_test__create_file "004.7-note.org"
    "$NT_SCRIPT" r 4.7 "renamed" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.7-renamed.org" \
        "rename should preserve .org extension in hierarchical filename"
}

test_hier_no_title_variant_rename() {
    # 004.7.md (no title) should get a delimiter when renamed
    nt_test__create_file "004.7.md"
    "$NT_SCRIPT" r 4.7 "new-title" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.7-new-title.md" \
        "rename of no-title hierarchical file should add - delimiter"
}

#####################################################################
# Tests — cmd_rename: hierarchical index
#####################################################################

test_hier_rename_by_hierarchical_index() {
    nt_test__create_file "004.7-old.md"
    "$NT_SCRIPT" r 4.7 "updated" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.7-updated.md" \
        "r 4.7 should rename hierarchical doc"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004.7-old.md" \
        "original hierarchical doc should be gone"
}

test_hier_rename_last_with_hierarchical() {
    nt_test__create_file "004.7-sub.md"
    "$NT_SCRIPT" rl "renamed" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.7-renamed.md" \
        "rl should rename last hierarchical doc"
}

#####################################################################
# Tests — cmd_renumber: hierarchical indices
#####################################################################

test_hier_renumber_hierarchical_single() {
    nt_test__create_file "004.1-note.md"
    "$NT_SCRIPT" rn 4.1 4.5 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.5-note.md" \
        "rn 4.1 4.5 should move 004.1 to 004.5"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004.1-note.md" \
        "original 004.1 should be gone"
}

test_hier_renumber_hierarchical_run() {
    nt_test__create_file "004.1-a.md"
    nt_test__create_file "004.2-b.md"
    nt_test__create_file "004.3-c.md"
    "$NT_SCRIPT" rn 4.1 4.5 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.5-a.md" "004.1 -> 004.5"
    nt_test__assert_file_exists "$NT_TEST_DIR/004.6-b.md" "004.2 -> 004.6"
    nt_test__assert_file_exists "$NT_TEST_DIR/004.7-c.md" "004.3 -> 004.7"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004.1-a.md" "004.1 gone"
}

test_hier_renumber_depth_mismatch_fails() {
    nt_test__create_file "004.1-note.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" rn 4.1 5
}

test_hier_renumber_collision_hierarchical() {
    nt_test__create_file "004.1-a.md"
    nt_test__create_file "004.5-occupied.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" rn 4.1 4.5
}

test_hier_renumber_flat_still_works() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "004-b.md"
    "$NT_SCRIPT" rn 3 7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/007-a.md" "003 -> 007"
    nt_test__assert_file_exists "$NT_TEST_DIR/008-b.md" "004 -> 008"
}

#####################################################################
# Tests — nth-to-last with hierarchical ordering
#####################################################################

test_hier_last_nth_hierarchical() {
    # 003.9, 003.10, 004 — last=004, 2nd-to-last=003.10, 3rd=003.9
    nt_test__create_file "003.9-a.md"
    nt_test__create_file "003.10-b.md"
    nt_test__create_file "004-c.md"
    nt_test__assert_output_contains "003.10-b.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l 2
}

#####################################################################
# Tests — validate_index: hierarchical inputs
#####################################################################

test_hier_validate_hierarchical_accepted() {
    nt_test__create_file "004.7-note.md"
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" 4.7
}

test_hier_validate_zero_start_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" 0.1
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_HIERARCHICAL=(
    test_hier_open_simple_still_works
    test_hier_open_by_hierarchical_index
    test_hier_open_deep_hierarchical_index
    test_hier_open_does_not_match_wrong_index
    test_hier_open_no_title_variant
    test_hier_last_flat_wins_over_sub
    test_hier_last_sub_within_same_parent
    test_hier_last_mixed_flat_and_sub
    test_hier_last_index_hierarchical
    test_hier_last_index_flat_unchanged
    test_hier_new_increments_from_flat
    test_hier_new_increments_last_component_of_hierarchical
    test_hier_new_increments_carry_at_last_component
    test_hier_new_with_title_after_hierarchical
    test_hier_new_inherits_delimiter_from_hierarchical
    test_hier_delimiter_hyphen_in_hierarchical
    test_hier_delimiter_underscore_in_hierarchical
    test_hier_extension_preserved_in_hierarchical
    test_hier_no_title_variant_rename
    test_hier_rename_by_hierarchical_index
    test_hier_rename_last_with_hierarchical
    test_hier_renumber_hierarchical_single
    test_hier_renumber_hierarchical_run
    test_hier_renumber_depth_mismatch_fails
    test_hier_renumber_collision_hierarchical
    test_hier_renumber_flat_still_works
    test_hier_last_nth_hierarchical
    test_hier_validate_hierarchical_accepted
    test_hier_validate_zero_start_fails
)
