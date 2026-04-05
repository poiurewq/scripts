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
    "$CLK_SCRIPT" edit 1 start 2026-01-01T08:30:00 >/dev/null 2>&1
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
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit 1 end 2026-01-01T10:00:00
    clk_test__assert_output_contains "active record" "$CLK_SCRIPT" edit 1 end 2026-01-01T10:00:00
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
    "$CLK_SCRIPT" edit 1 break 10 >/dev/null 2>&1
    clk_test__assert_log_line 1 '	600	'
}

#####################################################################
# Tests — clk edit pause
#####################################################################

test_edit_pause() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit 1 pause 2026-01-01T10:00:00 >/dev/null 2>&1
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
    "$CLK_SCRIPT" edit 1 pause clear >/dev/null 2>&1
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
    "$CLK_SCRIPT" edit 1 delete >/dev/null 2>&1
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

test_edit_shows_before_after() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" edit -1 tag newtag 2>&1)"
    # Should show both before and after lines
    if ! printf '%s' "$output" | grep -q "before:"; then
        printf 'FAIL: edit output should include "before:" line\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$output" | grep -q "after:"; then
        printf 'FAIL: edit output should include "after:" line\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    # Before line should contain old tag, after line should contain new tag
    clk_test__assert_output_contains "work" printf '%s' "$(printf '%s' "$output" | grep 'before:')" &&
    clk_test__assert_output_contains "newtag" printf '%s' "$(printf '%s' "$output" | grep 'after:')"
}

test_edit_before_after_shows_full_timestamps() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" edit -1 start 2026-01-01T09:45:00 2>&1)"
    # Both before and after lines should show full timestamps (raw format)
    clk_test__assert_output_contains "2026-01-01T09:30:00" printf '%s' "$(printf '%s' "$output" | grep 'before:')" &&
    clk_test__assert_output_contains "2026-01-01T09:45:00" printf '%s' "$(printf '%s' "$output" | grep 'after:')"
}

test_edit_delete_no_before_after() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" edit -1 delete 2>&1)"
    # Delete should show "Deleted record", not "before/after"
    if printf '%s' "$output" | grep -q "before:"; then
        printf 'FAIL: delete should not show before/after\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    clk_test__assert_output_contains "Deleted record" printf '%s' "$output"
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

test_edit_alias_e() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" e -1 tag newtag >/dev/null 2>&1
    clk_test__assert_log_line 1 'newtag'
}

test_edit_start_simplified_timestamp() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Use yyyy-mm-ddTHH:MM format
    "$CLK_SCRIPT" edit -1 start 2026-01-01T09:30 >/dev/null 2>&1
    clk_test__assert_log_line 1 '2026-01-01T09:30:00'
}

test_edit_end_simplified_timestamp() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Use yyyy-mm-ddTHH:MM format
    "$CLK_SCRIPT" edit -1 end 2026-01-01T10:30 >/dev/null 2>&1
    clk_test__assert_log_line 1 '2026-01-01T10:30:00'
}

test_edit_start_date_only_timestamp() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Use yyyy-mm-dd format (midnight)
    "$CLK_SCRIPT" edit -1 start 2026-01-01 >/dev/null 2>&1
    clk_test__assert_log_line 1 '2026-01-01T00:00:00'
}

#####################################################################
# Tests — clk edit end --adjust
#####################################################################

test_edit_end_adjust_active_default() {
    # Default behavior: adjusting end recalculates active time
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Original: start=09:00, end=10:00, length=3600, break=0
    "$CLK_SCRIPT" edit -1 end 2026-01-01T10:30:00 >/dev/null 2>&1
    # New: span=90m, break=0 → length=5400
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:30:00	work	5400	0'
}

test_edit_end_adjust_break() {
    # Add a session with break: start=09:00, end=10:00, break=600 (10m), length=2400 (40m)
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" edit -1 break 10 >/dev/null 2>&1
    # Now: start=09:00, end=10:00, break=600, length=3000 (50m)
    # Move end to 10:30 --adjust break → keep active=3000, new break = 5400-3000 = 2400
    "$CLK_SCRIPT" edit -1 end 2026-01-01T10:30:00 --adjust break >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:30:00	work	3000	2400'
}

test_edit_end_adjust_break_negative() {
    # If keeping active would make break negative, should fail
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # length=3600, break=0. If we move end to 09:30 --adjust break → break = -1800
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 end 2026-01-01T09:30:00 --adjust break
}

#####################################################################
# Tests — clk edit active (new field)
#####################################################################

test_edit_active_adjust_start() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Original: start=09:00, end=10:00, length=3600, break=0
    # Set active to 30m (1800s), --adjust start → new start = 10:00 - 1800 - 0 = 09:30
    "$CLK_SCRIPT" edit -1 active 30m --adjust start >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:30:00	2026-01-01T10:00:00	work	1800	0'
}

test_edit_active_adjust_end() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Set active to 90m (5400s), --adjust end → new end = 09:00 + 5400 + 0 = 10:30
    "$CLK_SCRIPT" edit -1 active 1h30m --adjust end >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:30:00	work	5400	0'
}

test_edit_active_adjust_break() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Original: span=3600, length=3600, break=0
    # Set active to 50m (3000s), --adjust break → break = 3600 - 3000 = 600
    "$CLK_SCRIPT" edit -1 active 50 --adjust break >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:00:00	work	3000	600'
}

test_edit_active_adjust_break_exceeds_span() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Set active to 90m with --adjust break → break = 3600 - 5400 = negative
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 active 90 --adjust break
}

test_edit_active_requires_adjust() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # active without --adjust should fail
    clk_test__assert_exit 1 "$CLK_SCRIPT" edit -1 active 30
}

test_edit_active_duration_string() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Test 2h format
    "$CLK_SCRIPT" edit -1 active 2h --adjust end >/dev/null 2>&1
    # new end = 09:00 + 7200 + 0 = 11:00
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T11:00:00	work	7200	0'
}

#####################################################################
# Tests — clk edit break with duration strings and --adjust
#####################################################################

test_edit_break_duration_string() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Use "30m" instead of "30"
    "$CLK_SCRIPT" edit -1 break 30m >/dev/null 2>&1
    # span=3600, new break=1800, length=1800
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:00:00	work	1800	1800'
}

test_edit_break_duration_hm() {
    "$CLK_SCRIPT" add work for 120 at 2026-01-01T12:00:00 >/dev/null 2>&1
    # Original: start=10:00, end=12:00, length=7200, break=0
    "$CLK_SCRIPT" edit -1 break 1h --adjust active >/dev/null 2>&1
    # break=3600, length=3600
    clk_test__assert_log_line 1 '^done	2026-01-01T10:00:00	2026-01-01T12:00:00	work	3600	3600'
}

test_edit_break_adjust_start() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Original: start=09:00, end=10:00, length=3600, break=0
    # Set break=30m, --adjust start → new start = 10:00 - 3600 - 1800 = 08:30
    "$CLK_SCRIPT" edit -1 break 30 --adjust start >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T08:30:00	2026-01-01T10:00:00	work	3600	1800'
}

test_edit_break_adjust_end() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Set break=30m, --adjust end → new end = 09:00 + 3600 + 1800 = 10:30
    "$CLK_SCRIPT" edit -1 break 30 --adjust end >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:30:00	work	3600	1800'
}

test_edit_interactive_requires_tty() {
    # Piped input should fail
    clk_test__assert_exit 1 sh -c "echo '' | $CLK_SCRIPT edit"
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
    test_edit_shows_before_after
    test_edit_before_after_shows_full_timestamps
    test_edit_delete_no_before_after
    test_edit_missing_field
    test_edit_unknown_field
    test_edit_bad_index
    test_edit_alias_e
    test_edit_start_simplified_timestamp
    test_edit_end_simplified_timestamp
    test_edit_start_date_only_timestamp

    # edit end --adjust
    test_edit_end_adjust_active_default
    test_edit_end_adjust_break
    test_edit_end_adjust_break_negative

    # edit active (new field)
    test_edit_active_adjust_start
    test_edit_active_adjust_end
    test_edit_active_adjust_break
    test_edit_active_adjust_break_exceeds_span
    test_edit_active_requires_adjust
    test_edit_active_duration_string

    # edit break duration + --adjust
    test_edit_break_duration_string
    test_edit_break_duration_hm
    test_edit_break_adjust_start
    test_edit_break_adjust_end

    # interactive mode
    test_edit_interactive_requires_tty
)
