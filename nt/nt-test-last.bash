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
    nt_test__assert_output_equals "7" "$NT_SCRIPT" l i
}

test_last_n_prints_highest() {
    nt_test__create_file "003.md"
    nt_test__create_file "010-note.md"
    nt_test__assert_output_equals "10" "$NT_SCRIPT" l i
}

test_last_n_no_docs() {
    nt_test__assert_exit 2 "$NT_SCRIPT" l i
}

test_last_index_long_form() {
    nt_test__create_file "005-note.md"
    nt_test__assert_output_equals "5" "$NT_SCRIPT" l index
}

#####################################################################
# Tests — nt l <N>: open nth-to-last (Phase 3)
#####################################################################

test_last_nth_to_last_1() {
    # l 1 is the same as l (opens the last doc)
    nt_test__create_file "001-first.md"
    nt_test__create_file "002-second.md"
    nt_test__create_file "003-third.md"
    nt_test__assert_output_contains "003-third.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l 1
}

test_last_nth_to_last_2() {
    nt_test__create_file "001-first.md"
    nt_test__create_file "002-second.md"
    nt_test__create_file "003-third.md"
    nt_test__assert_output_contains "002-second.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l 2
}

test_last_nth_to_last_3() {
    nt_test__create_file "001-first.md"
    nt_test__create_file "002-second.md"
    nt_test__create_file "003-third.md"
    nt_test__assert_output_contains "001-first.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" l 3
}

test_last_nth_exceeds_count_fails() {
    nt_test__create_file "001-first.md"
    nt_test__create_file "002-second.md"
    nt_test__assert_exit 2 "$NT_SCRIPT" l 5
}

test_last_nth_exceeds_count_message() {
    nt_test__create_file "001-first.md"
    nt_test__assert_output_contains "Only 1 indexed document" "$NT_SCRIPT" l 2
}

#####################################################################
# Tests — nt last: long-form alias (Phase 3)
#####################################################################

test_last_alias_opens_last_doc() {
    nt_test__create_file "001-first.md"
    nt_test__create_file "005-fifth.md"
    nt_test__assert_output_contains "005-fifth.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" last
}

test_last_alias_n_prints_number() {
    nt_test__create_file "004-note.md"
    nt_test__assert_output_equals "4" "$NT_SCRIPT" last i
}

test_last_alias_nth_to_last() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "002-b.md"
    nt_test__assert_output_contains "001-a.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" last 2
}

#####################################################################
# Tests — hyphen-prefixed forms: -l / --last (Phase 3)
#####################################################################

test_last_hyphen_short_opens_last() {
    nt_test__create_file "001-first.md"
    nt_test__create_file "004-fourth.md"
    nt_test__assert_output_contains "004-fourth.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" -l
}

test_last_hyphen_long_opens_last() {
    nt_test__create_file "002-second.md"
    nt_test__assert_output_contains "002-second.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" --last
}

test_last_hyphen_index() {
    nt_test__create_file "006-note.md"
    nt_test__assert_output_equals "6" "$NT_SCRIPT" --last i
}

test_last_hyphen_nth_to_last() {
    nt_test__create_file "001-a.md"
    nt_test__create_file "002-b.md"
    nt_test__create_file "003-c.md"
    nt_test__assert_output_contains "001-a.md" \
        env NT_EDITOR="echo" "$NT_SCRIPT" --last 3
}

test_last_hyphen_skips_next_flag() {
    # --last with no numeric/index arg should open last and leave -R for the loop
    nt_test__create_file "001-first.md"
    nt_test__create_file "README.md"
    local output
    output="$(env NT_EDITOR="echo" "$NT_SCRIPT" --last -R 2>&1)"
    printf '%s' "$output" | grep -q "001-first.md" || { printf 'FAIL: missing 001-first.md\n  output: %s\n' "$output"; NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1; }
    printf '%s' "$output" | grep -q "README.md"   || { printf 'FAIL: missing README.md\n  output: %s\n' "$output"; NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 )); return 1; }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
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
    test_last_index_long_form
    test_last_nth_to_last_1
    test_last_nth_to_last_2
    test_last_nth_to_last_3
    test_last_nth_exceeds_count_fails
    test_last_nth_exceeds_count_message
    test_last_alias_opens_last_doc
    test_last_alias_n_prints_number
    test_last_alias_nth_to_last
    test_last_hyphen_short_opens_last
    test_last_hyphen_long_opens_last
    test_last_hyphen_index
    test_last_hyphen_nth_to_last
    test_last_hyphen_skips_next_flag
)
