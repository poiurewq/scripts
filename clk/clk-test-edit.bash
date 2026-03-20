#!/usr/bin/env bash
# clk-test-edit.bash — integration tests for edit subcommand
#
# Sourced by clk-test; do not run directly.
# Defines: CLK_TESTS_EDIT (array of test function names)

#####################################################################
# Tests — clk edit tag
#####################################################################

test_edit_tag() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 tag newtag >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:30:00	2026-01-01T10:00:00	newtag	1800	0'
}

test_edit_tag_validates() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Numeric tag should fail
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 tag 123
}

#####################################################################
# Tests — clk edit start
#####################################################################

test_edit_start() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Original: start=09:00, end=10:00, length=3600, break=0
    "$CLK_SCRIPT" edit -1 start 2026-01-01T09:30:00 >/dev/null 2>&1
    # New: start=09:30, end=10:00, length=1800, break=0
    clk_test__assert_log_line 1 '^done	2026-01-01T09:30:00	2026-01-01T10:00:00	work	1800	0'
}

test_edit_start_recalculates_length() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 start 2026-01-01T08:00:00 >/dev/null 2>&1
    # New span: 08:00 → 10:00 = 7200s, break=0, length=7200
    clk_test__assert_log_line 1 '^done	2026-01-01T08:00:00	2026-01-01T10:00:00	work	7200	0'
}

test_edit_start_after_end() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 start 2026-01-01T11:00:00
}

test_edit_start_on_active() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 start 2026-01-01T08:30:00 >/dev/null 2>&1
    clk_test__assert_log_line 1 '^active	2026-01-01T08:30:00	'
}

#####################################################################
# Tests — clk edit end
#####################################################################

test_edit_end() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Original: start=09:00, end=10:00, length=3600
    "$CLK_SCRIPT" edit -1 end 2026-01-01T11:00:00 >/dev/null 2>&1
    # New: start=09:00, end=11:00, length=7200
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T11:00:00	work	7200	0'
}

test_edit_end_recalculates_length() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 break 10 >/dev/null 2>&1
    # Now: start=09:00, end=10:00, break=600, length=3000
    "$CLK_SCRIPT" edit -1 end 2026-01-01T11:00:00 >/dev/null 2>&1
    # New: start=09:00, end=11:00, break=600, length=6600
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T11:00:00	work	6600	600'
}

test_edit_end_on_active() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 end 2026-01-01T10:00:00
    clk_test__assert_output_contains "active record" "$CLK_SCRIPT" edit -1 end 2026-01-01T10:00:00
}

test_edit_end_before_start() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 end 2026-01-01T08:00:00
}

#####################################################################
# Tests — clk edit break
#####################################################################

test_edit_break() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 break 5 >/dev/null 2>&1
    # start=09:00, end=10:00, break=300, length=3600-300=3300
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:00:00	work	3300	300'
}

test_edit_break_exceeds_span() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # 60-minute session, break of 90 should fail
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 break 90
}

test_edit_break_on_active() {
    # Break on active records should work (no length recalc needed)
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 break 10 >/dev/null 2>&1
    clk_test__assert_log_line 1 '	600	'
}

#####################################################################
# Tests — clk edit pause
#####################################################################

test_edit_pause() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 pause 2026-01-01T10:00:00 >/dev/null 2>&1
    # PAUSED_AT should be set to epoch of 2026-01-01T10:00:00
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local line paused_field
    line="$(tail -1 "$log_file")"
    paused_field="$(printf '%s' "$line" | cut -d'	' -f7)"
    if [ -z "$paused_field" ]; then
        printf 'FAIL: PAUSED_AT should be set\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_edit_pause_clear() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 pause clear >/dev/null 2>&1
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local line paused_field
    line="$(tail -1 "$log_file")"
    paused_field="$(printf '%s' "$line" | cut -d'	' -f7)"
    if [ -n "$paused_field" ]; then
        printf 'FAIL: PAUSED_AT should be cleared, got: %s\n' "$paused_field"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_edit_pause_on_done() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 pause 2026-01-01T10:00:00
}

#####################################################################
# Tests — clk edit on (description)
#####################################################################

test_edit_on() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 on new description here >/dev/null 2>&1
    clk_test__assert_log_line 1 'new description here$'
}

test_edit_on_replaces() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 on old desc >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 on replaced desc >/dev/null 2>&1
    clk_test__assert_log_line 1 'replaced desc$'
}

#####################################################################
# Tests — clk edit delete
#####################################################################

test_edit_delete() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add play for 60 at 2026-01-01T12:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 delete >/dev/null 2>&1
    # Only work record should remain
    local count
    count="$(clk__record_count)"
    clk_test__assert_equals "1" "$count" "should have 1 record after delete"
    clk_test__assert_log_line 1 '^done.*work'
}

test_edit_delete_active() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 delete >/dev/null 2>&1
    local count
    count="$(clk__record_count)"
    clk_test__assert_equals "0" "$count" "should have 0 records after deleting active"
}

test_edit_delete_shows_removed() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "Deleted record" "$CLK_SCRIPT" edit -1 delete
}

#####################################################################
# Tests — clk edit misc
#####################################################################

test_edit_triggers_undo() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 tag newtag >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: edit should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_edit_index_out_of_range() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -5 tag newtag
}

test_edit_second_record() {
    # -2 should target the second-to-last record
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add play for 60 at 2026-01-01T12:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -2 tag renamed >/dev/null 2>&1
    # Line 2 (first data line) should now have tag=renamed
    clk_test__assert_log_line 2 '^done.*renamed'
}

test_edit_confirmation_output() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "Updated record" "$CLK_SCRIPT" edit -1 tag newtag
}

test_edit_missing_field() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1
}

test_edit_unknown_field() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 bogus value
}

test_edit_bad_index() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -abc tag newtag
}

#####################################################################
# Test registry
#####################################################################

CLK_TESTS_EDIT=(
    test_edit_tag
    test_edit_tag_validates
    test_edit_start
    test_edit_start_recalculates_length
    test_edit_start_after_end
    test_edit_start_on_active
    test_edit_end
    test_edit_end_recalculates_length
    test_edit_end_on_active
    test_edit_end_before_start
    test_edit_break
    test_edit_break_exceeds_span
    test_edit_break_on_active
    test_edit_pause
    test_edit_pause_clear
    test_edit_pause_on_done
    test_edit_on
    test_edit_on_replaces
    test_edit_delete
    test_edit_delete_active
    test_edit_delete_shows_removed
    test_edit_triggers_undo
    test_edit_index_out_of_range
    test_edit_second_record
    test_edit_confirmation_output
    test_edit_missing_field
    test_edit_unknown_field
    test_edit_bad_index
)
