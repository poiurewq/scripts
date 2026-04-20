#!/usr/bin/env bash
# nt-test-hierarchical.bash — tests for hierarchical index support
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
    nt_test__create_file "004.007-sub-note.md"
    nt_test__assert_output_contains "004.007-sub-note.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 4.7
}

test_hier_open_deep_hierarchical_index() {
    nt_test__create_file "004.007.010-deep.md"
    nt_test__assert_output_contains "004.007.010-deep.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 4.7.10
}

test_hier_open_does_not_match_wrong_index() {
    # 004.007 should NOT match 004.070-other.md
    nt_test__create_file "004.070-other.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" 4.7
}

test_hier_open_no_title_variant() {
    # 004.007.md — hierarchical index with no title
    nt_test__create_file "004.007.md"
    nt_test__assert_output_contains "004.007.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 4.7
}

#####################################################################
# Tests — last_indexed_doc: hierarchical ordering
#####################################################################

test_hier_last_flat_wins_over_sub() {
    # 004 > 003.009 (cross-depth: 004 > 003.*)
    nt_test__create_file "003.009-sub.md"
    nt_test__create_file "004-main.md"
    nt_test__assert_output_contains "004-main.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l
}

test_hier_last_sub_within_same_parent() {
    # 003.010 > 003.009 (numeric, not lexicographic)
    nt_test__create_file "003.009-sub.md"
    nt_test__create_file "003.010-sub.md"
    nt_test__assert_output_contains "003.010-sub.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l
}

test_hier_last_mixed_flat_and_sub() {
    # 004.001 > 004 (sub-index follows parent)
    nt_test__create_file "003.md"
    nt_test__create_file "004.md"
    nt_test__create_file "004.001-sub.md"
    nt_test__assert_output_contains "004.001-sub.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l
}

test_hier_last_index_hierarchical() {
    # li should print the full hierarchical index (stripped of leading zeros)
    nt_test__create_file "004.007-note.md"
    nt_test__create_file "004.010-later.md"
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
    # Last is 004.007; next should be 004.008
    nt_test__create_file "003.md"
    nt_test__create_file "004.007-note.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.008.md" \
        "n after 004.007 should create 004.008"
}

test_hier_new_increments_carry_at_last_component() {
    # Last is 004.009; next should be 004.010 (no carry to parent)
    nt_test__create_file "004.009-note.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.010.md" \
        "n after 004.009 should create 004.010 (not 005)"
}

test_hier_new_with_title_after_hierarchical() {
    nt_test__create_file "004.007-note.md"
    "$NT_SCRIPT" n "sub note" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.008-sub-note.md" \
        "n with title after 004.007 should create 004.008-sub-note"
}

test_hier_new_inherits_delimiter_from_hierarchical() {
    nt_test__create_file "004.007__old.md"
    "$NT_SCRIPT" n "new" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.008__new.md" \
        "n should inherit __ delimiter from hierarchical last doc"
}

#####################################################################
# Tests — get_delimiter / get_extension with hierarchical filenames
#####################################################################

test_hier_delimiter_hyphen_in_hierarchical() {
    nt_test__create_file "004.007-old-title.md"
    "$NT_SCRIPT" r 4.7 "new title" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007-new-title.md" \
        "rename should preserve - delimiter in hierarchical filename"
}

test_hier_delimiter_underscore_in_hierarchical() {
    nt_test__create_file "004.007__old.md"
    "$NT_SCRIPT" r 4.7 "updated" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007__updated.md" \
        "rename should preserve __ delimiter in hierarchical filename"
}

test_hier_extension_preserved_in_hierarchical() {
    nt_test__create_file "004.007-note.org"
    "$NT_SCRIPT" r 4.7 "renamed" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007-renamed.org" \
        "rename should preserve .org extension in hierarchical filename"
}

test_hier_no_title_variant_rename() {
    # 004.007.md (no title) should get a delimiter when renamed
    nt_test__create_file "004.007.md"
    "$NT_SCRIPT" r 4.7 "new-title" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007-new-title.md" \
        "rename of no-title hierarchical file should add - delimiter"
}

#####################################################################
# Tests — cmd_rename: hierarchical index
#####################################################################

test_hier_rename_by_hierarchical_index() {
    nt_test__create_file "004.007-old.md"
    "$NT_SCRIPT" r 4.7 "updated" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007-updated.md" \
        "r 4.7 should rename hierarchical doc"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004.007-old.md" \
        "original hierarchical doc should be gone"
}

test_hier_rename_last_with_hierarchical() {
    nt_test__create_file "004.007-sub.md"
    "$NT_SCRIPT" rl "renamed" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007-renamed.md" \
        "rl should rename last hierarchical doc"
}

#####################################################################
# Tests — cmd_renumber: hierarchical indices
#####################################################################

test_hier_renumber_hierarchical_single() {
    nt_test__create_file "004.001-note.md"
    "$NT_SCRIPT" ri 4.1 4.5 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.005-note.md" \
        "ri 4.1 4.5 should move 004.001 to 004.005"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004.001-note.md" \
        "original 004.001 should be gone"
}

test_hier_renumber_hierarchical_run() {
    nt_test__create_file "004.001-a.md"
    nt_test__create_file "004.002-b.md"
    nt_test__create_file "004.003-c.md"
    "$NT_SCRIPT" ri 4.1-4.3 4.5-4.7 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.005-a.md" "004.001 -> 004.005"
    nt_test__assert_file_exists "$NT_TEST_DIR/004.006-b.md" "004.002 -> 004.006"
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007-c.md" "004.003 -> 004.007"
    nt_test__assert_file_not_exists "$NT_TEST_DIR/004.001-a.md" "004.001 gone"
}

test_hier_renumber_collision_hierarchical() {
    nt_test__create_file "004.001-a.md"
    nt_test__create_file "004.005-occupied.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" ri 4.1 4.5
}

test_hier_renumber_flat_still_works() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "004-b.md"
    "$NT_SCRIPT" ri 3-4 7-8 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/007-a.md" "003 -> 007"
    nt_test__assert_file_exists "$NT_TEST_DIR/008-b.md" "004 -> 008"
}

#####################################################################
# Tests — nth-to-last with hierarchical ordering
#####################################################################

test_hier_last_nth_hierarchical() {
    # 003.009, 003.010, 004 — last=004, 2nd-to-last=003.010, 3rd=003.009
    nt_test__create_file "003.009-a.md"
    nt_test__create_file "003.010-b.md"
    nt_test__create_file "004-c.md"
    nt_test__assert_output_contains "003.010-b.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l 2
}

#####################################################################
# Tests — validate_index: hierarchical inputs
#####################################################################

test_hier_validate_hierarchical_accepted() {
    nt_test__create_file "004.007-note.md"
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" 4.7
}

test_hier_validate_zero_start_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" 0.1
}

#####################################################################
# Tests — Phase 5: range opening
#####################################################################

test_range_opens_all_in_range() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "004-b.md"
    nt_test__create_file "005-c.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 3-5 2>&1)" || true
    printf '%s' "$output" | grep -qF "003-a.md" || {
        printf 'FAIL: range should include 003-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "005-c.md" || {
        printf 'FAIL: range should include 005-c.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_range_skips_missing_indices() {
    nt_test__create_file "003-a.md"
    nt_test__create_file "005-c.md"
    # 004 is missing — should still succeed with 003 and 005
    nt_test__assert_exit 0 env NT_EDITOR="true" "$NT_SCRIPT" 3-5
}

test_range_empty_range_fails() {
    # No docs exist in range 10-15
    nt_test__assert_exit 2 "$NT_SCRIPT" 10-15
}

test_range_single_element() {
    nt_test__create_file "003-a.md"
    nt_test__assert_output_contains "003-a.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" 3-3
}

#####################################################################
# Tests — Phase 5: custom index (nt n i <index>)
#####################################################################

test_new_custom_index_flat() {
    "$NT_SCRIPT" n i 5 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/005.md" \
        "n i 5 should create 005.md"
}

test_new_custom_index_hierarchical() {
    "$NT_SCRIPT" n i 4.1 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.001.md" \
        "n i 4.1 should create 004.001.md"
}

test_new_custom_index_deep() {
    "$NT_SCRIPT" n i 4.7.10 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.007.010.md" \
        "n i 4.7.10 should create 004.007.010.md"
}

test_new_custom_index_with_title() {
    "$NT_SCRIPT" n i 4.1 my sub-note >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.001-my-sub-note.md" \
        "n i 4.1 my sub-note should create 004.001-my-sub-note.md"
}

test_new_custom_index_conflict_fails() {
    nt_test__create_file "005-existing.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" n i 5
}

test_new_custom_index_long_form() {
    "$NT_SCRIPT" n index 3.2 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003.002.md" \
        "n index 3.2 should create 003.002.md"
}

#####################################################################
# Tests — Phase 5: copy from existing (nt n c <index>)
#####################################################################

test_new_copy_content() {
    nt_test__create_file "003-source.md" "source content here"
    "$NT_SCRIPT" n c 3 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.md" \
        "n c 3 should create next doc"
    nt_test__assert_file_contains "$NT_TEST_DIR/004.md" "source content here" \
        "copied doc should have source content"
}

test_new_copy_inherits_extension() {
    nt_test__create_file "003-source.org" "org content"
    "$NT_SCRIPT" n c 3 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.org" \
        "n c 3 should inherit .org extension from source"
}

test_new_copy_with_title() {
    nt_test__create_file "003-source.md" "content"
    "$NT_SCRIPT" n c 3 my clone >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004-my-clone.md" \
        "n c 3 my clone should create 004-my-clone.md"
}

test_new_copy_long_form() {
    nt_test__create_file "003-source.md" "copied"
    "$NT_SCRIPT" n copy 3 >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/004.md" "copied" \
        "n copy 3 should copy content"
}

test_new_copy_missing_source_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" n c 99
}

#####################################################################
# Tests — Phase 5: combined i + c
#####################################################################

test_new_combined_index_and_copy() {
    nt_test__create_file "003-source.md" "original"
    "$NT_SCRIPT" n i 3.1 c 3 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003.001.md" \
        "n i 3.1 c 3 should create 003.001.md"
    nt_test__assert_file_contains "$NT_TEST_DIR/003.001.md" "original" \
        "combined i+c should copy content from source"
}

test_new_combined_reverse_order() {
    nt_test__create_file "003-source.md" "original"
    "$NT_SCRIPT" n c 3 i 3.1 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/003.001.md" \
        "n c 3 i 3.1 should create 003.001.md (order irrelevant)"
    nt_test__assert_file_contains "$NT_TEST_DIR/003.001.md" "original" \
        "reverse-order combined i+c should copy content"
}

test_new_combined_with_title() {
    nt_test__create_file "003-source.md" "data"
    "$NT_SCRIPT" n i 4.1 c 3 my sub-note >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/004.001-my-sub-note.md" \
        "n i 4.1 c 3 title should create correctly"
    nt_test__assert_file_contains "$NT_TEST_DIR/004.001-my-sub-note.md" "data" \
        "combined with title should copy source content"
}

test_new_copy_overrides_template() {
    printf 'template content\n' > "$NT_TEST_DIR/nt_template.md"
    nt_test__create_file "003-source.md" "source content"
    "$NT_SCRIPT" n c 3 >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/004.md" "source content" \
        "copy should override template"
}

#####################################################################
# Tests — Phase 5: hierarchical range opening (§5.7)
#####################################################################

test_range_hier_same_parent() {
    nt_test__create_file "001.003-a.md"
    nt_test__create_file "001.005-b.md"
    nt_test__create_file "001.007-c.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1.3-1.7 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.003-a.md" || {
        printf 'FAIL: range 1.3-1.7 should include 001.003-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "001.005-b.md" || {
        printf 'FAIL: range 1.3-1.7 should include 001.005-b.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "001.007-c.md" || {
        printf 'FAIL: range 1.3-1.7 should include 001.007-c.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_range_cross_depth() {
    # 3-5.2 should include flat 003, 004, 005 and sub-indices up to 005.002
    nt_test__create_file "003-a.md"
    nt_test__create_file "004-b.md"
    nt_test__create_file "004.001-sub.md"
    nt_test__create_file "005-c.md"
    nt_test__create_file "005.002-sub.md"
    nt_test__create_file "005.003-beyond.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 3-5.2 2>&1)" || true
    printf '%s' "$output" | grep -qF "003-a.md" || {
        printf 'FAIL: cross-depth range should include 003-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "004.001-sub.md" || {
        printf 'FAIL: cross-depth range should include 004.001-sub.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "005.002-sub.md" || {
        printf 'FAIL: cross-depth range should include 005.002-sub.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    # 005.003 is beyond 005.002, should NOT be included
    printf '%s' "$output" | grep -qF "005.003-beyond.md" && {
        printf 'FAIL: cross-depth range should NOT include 005.003-beyond.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_range_includes_sub_indices() {
    # nt 1-2 should include sub-indices within the range
    nt_test__create_file "001-a.md"
    nt_test__create_file "001.001-sub.md"
    nt_test__create_file "001.002-sub2.md"
    nt_test__create_file "002-b.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1-2 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.001-sub.md" || {
        printf 'FAIL: range 1-2 should include sub-index 001.001\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "002-b.md" || {
        printf 'FAIL: range 1-2 should include 002-b.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_range_start_greater_than_end_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" 5-3
}

test_range_hier_empty_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" 1.3-1.7
}

#####################################################################
# Tests — Phase 5: subtree open (§5.8)
#   NUM.. = all descendants, NUM. = immediate children only
#####################################################################

test_subtree_finds_sub_docs() {
    nt_test__create_file "001.md"
    nt_test__create_file "001.001-a.md"
    nt_test__create_file "001.002-b.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1.. 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.001-a.md" || {
        printf 'FAIL: subtree 1.. should include 001.001-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "001.002-b.md" || {
        printf 'FAIL: subtree 1.. should include 001.002-b.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_subtree_excludes_parent() {
    nt_test__create_file "001-parent.md"
    nt_test__create_file "001.001-child.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1.. 2>&1)" || true
    printf '%s' "$output" | grep -qF "001-parent.md" && {
        printf 'FAIL: subtree 1.. should NOT include parent 001-parent.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_subtree_deep_nesting() {
    nt_test__create_file "001.002-a.md"
    nt_test__create_file "001.002.001-deep.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1.. 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.002.001-deep.md" || {
        printf 'FAIL: subtree 1.. should include deeply nested 001.002.001-deep.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_subtree_specific_parent() {
    nt_test__create_file "001.002-a.md"
    nt_test__create_file "001.002.001-b.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1.2.. 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.002.001-b.md" || {
        printf 'FAIL: subtree 1.2.. should include 001.002.001-b.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    # Should NOT include the parent 001.002-a.md
    printf '%s' "$output" | grep -qF "001.002-a.md" && {
        printf 'FAIL: subtree 1.2.. should NOT include parent 001.002-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_subtree_empty_fails() {
    nt_test__create_file "001.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" 1..
}

test_subtree_no_docs_at_all_fails() {
    nt_test__assert_exit 2 "$NT_SCRIPT" 5..
}

test_subtree_chaining_with_readme() {
    nt_test__create_file "001.001-a.md"
    nt_test__create_file "README.md" "# Readme"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1.. R 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.001-a.md" || {
        printf 'FAIL: chained subtree+R should include 001.001-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "README.md" || {
        printf 'FAIL: chained subtree+R should include README.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_subtree_hyphen_prefix_chaining() {
    nt_test__create_file "001.001-a.md"
    nt_test__create_file "README.md" "# Readme"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" -1.. -R 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.001-a.md" || {
        printf 'FAIL: chained -1.. -R should include 001.001-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "README.md" || {
        printf 'FAIL: chained -1.. -R should include README.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

# ── Immediate children (NUM.) ──

test_subtree_immediate_children_only() {
    nt_test__create_file "001.001-a.md"
    nt_test__create_file "001.002-b.md"
    nt_test__create_file "001.002.001-deep.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1. 2>&1)" || true
    printf '%s' "$output" | grep -qF "001.001-a.md" || {
        printf 'FAIL: 1. should include immediate child 001.001-a.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    printf '%s' "$output" | grep -qF "001.002-b.md" || {
        printf 'FAIL: 1. should include immediate child 001.002-b.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
    # Deep nested doc should NOT be included
    printf '%s' "$output" | grep -qF "001.002.001-deep.md" && {
        printf 'FAIL: 1. should NOT include grandchild 001.002.001-deep.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_subtree_immediate_excludes_parent() {
    nt_test__create_file "001-parent.md"
    nt_test__create_file "001.001-child.md"
    local output
    output="$(NT_EDITOR="echo" "$NT_SCRIPT" 1. 2>&1)" || true
    printf '%s' "$output" | grep -qF "001-parent.md" && {
        printf 'FAIL: 1. should NOT include parent 001-parent.md\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

test_subtree_immediate_empty_fails() {
    nt_test__create_file "001.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" 1.
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
    test_hier_renumber_collision_hierarchical
    test_hier_renumber_flat_still_works
    test_hier_last_nth_hierarchical
    test_hier_validate_hierarchical_accepted
    test_hier_validate_zero_start_fails
    test_range_opens_all_in_range
    test_range_skips_missing_indices
    test_range_empty_range_fails
    test_range_single_element
    test_new_custom_index_flat
    test_new_custom_index_hierarchical
    test_new_custom_index_deep
    test_new_custom_index_with_title
    test_new_custom_index_conflict_fails
    test_new_custom_index_long_form
    test_new_copy_content
    test_new_copy_inherits_extension
    test_new_copy_with_title
    test_new_copy_long_form
    test_new_copy_missing_source_fails
    test_new_combined_index_and_copy
    test_new_combined_reverse_order
    test_new_combined_with_title
    test_new_copy_overrides_template
    test_range_hier_same_parent
    test_range_cross_depth
    test_range_includes_sub_indices
    test_range_start_greater_than_end_fails
    test_range_hier_empty_fails
    test_subtree_finds_sub_docs
    test_subtree_excludes_parent
    test_subtree_deep_nesting
    test_subtree_specific_parent
    test_subtree_empty_fails
    test_subtree_no_docs_at_all_fails
    test_subtree_chaining_with_readme
    test_subtree_hyphen_prefix_chaining
    test_subtree_immediate_children_only
    test_subtree_immediate_excludes_parent
    test_subtree_immediate_empty_fails
)
