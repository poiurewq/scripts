#!/usr/bin/env bash
# clk-test-mutation.bash — integration tests for add (session/time), add-break,
#                           extend, remove, undo, redo
#
# Sourced by clk-test; do not run directly.
# Defines: CLK_TESTS_MUTATION (array of test function names)

#####################################################################
# Tests — clk add (session) (integration)
#####################################################################

test_add_session_basic() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Should create done record: 30m = 1800s, start = 09:30, end = 10:00
    clk_test__assert_log_line 1 '^done	2026-01-01T09:30:00	2026-01-01T10:00:00	work	1800	0'
}

test_add_session_with_description() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-01T10:00:00 on coding stuff >/dev/null 2>&1
    clk_test__assert_log_line 1 'coding stuff$'
}

test_add_session_creates_undo() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: add session should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_add_session_ordering_with_active() {
    # add should insert before active records
    "$CLK_SCRIPT" in play at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T08:30:00 >/dev/null 2>&1
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local line2 line3
    line2="$(awk 'NR==2' "$log_file")"
    line3="$(awk 'NR==3' "$log_file")"
    if ! printf '%s' "$line2" | grep -q '^done.*work'; then
        printf 'FAIL: done record should be before active\n  actual: %s\n' "$line2"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$line3" | grep -q '^active.*play'; then
        printf 'FAIL: active record should remain at end\n  actual: %s\n' "$line3"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_add_session_confirmation_output() {
    clk_test__assert_output_contains "Added session" "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00:00
}

test_add_session_missing_for() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" add work
}

test_add_session_numeric_tag_rejected() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" add 123 for 30 at 2026-01-01T10:00:00
}

test_add_session_alias_a() {
    "$CLK_SCRIPT" a work for 30 at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:30:00	2026-01-01T10:00:00	work	1800	0'
}

test_add_time_alias_a() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" a 10 to work >/dev/null 2>&1
    clk_test__assert_log_line 1 'active	2026-01-01T08:50:00'
}

test_add_session_simplified_timestamp_no_seconds() {
    "$CLK_SCRIPT" add work for 30 at 2026-01-01T10:00 >/dev/null 2>&1
    clk_test__assert_log_line 1 '^done	2026-01-01T09:30:00	2026-01-01T10:00:00	work	1800	0'
}

#####################################################################
# Tests — clk add (time to active) (integration)
#####################################################################

test_add_time_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add 15 to work >/dev/null 2>&1
    # Start time should be moved back 15 min to 08:45
    clk_test__assert_log_line 1 '^active	2026-01-01T08:45:00		work'
}

test_add_time_implicit_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" add 10
}

test_add_time_implicit_tag_correct() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add 30 >/dev/null 2>&1
    clk_test__assert_log_line 1 '^active	2026-01-01T08:30:00		work'
}

test_add_time_ambiguous_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" add 15
}

test_add_time_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" add 15 to work 2>&1)"
    clk_test__assert_output_contains "Added 15 minutes" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-01-01 09:00" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-01-01 08:45" printf '%s' "$output"
}

test_add_time_creates_undo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    "$CLK_SCRIPT" add 10 >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: add time should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_add_time_no_active() {
    clk_test__assert_exit 5 "$CLK_SCRIPT" add 15
}

#####################################################################
# Tests — clk add-break (integration)
#####################################################################

test_add_break_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add-break 10 >/dev/null 2>&1
    # BREAK_SECS should be 600
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local break_secs
    break_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f6)"
    clk_test__assert_equals "600" "$break_secs" "add-break sets BREAK_SECS"
}

test_add_break_accumulates() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add-break 10 >/dev/null 2>&1
    "$CLK_SCRIPT" add-break 5 >/dev/null 2>&1
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local break_secs
    break_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f6)"
    clk_test__assert_equals "900" "$break_secs" "add-break accumulates"
}

test_add_break_while_paused() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    clk_test__assert_exit 5 "$CLK_SCRIPT" add-break 10
}

test_add_break_while_paused_message() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    clk_test__assert_output_contains "currently paused" "$CLK_SCRIPT" add-break 10
}

test_add_break_with_to_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add-break 10 to work >/dev/null 2>&1
    # Only work's break should be 600; play's should still be 0
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local work_break play_break
    work_break="$(awk -F'\t' '$4=="work" {print $6}' "$log_file")"
    play_break="$(awk -F'\t' '$4=="play" {print $6}' "$log_file")"
    clk_test__assert_equals "600" "$work_break" "add-break to work" &&
    clk_test__assert_equals "0" "$play_break" "play break unchanged"
}

test_add_break_alias_ab() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" ab 5
}

test_add_break_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" add-break 10 2>&1)"
    clk_test__assert_output_contains "Added 10m break" printf '%s' "$output" &&
    clk_test__assert_output_contains "Total break so far" printf '%s' "$output"
}

test_add_break_creates_undo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    "$CLK_SCRIPT" add-break 5 >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: add-break should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_add_break_missing_minutes() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" add-break
}

#####################################################################
# Tests — clk extend (integration)
#####################################################################

test_extend_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" extend at 2026-01-01T10:30:00 >/dev/null 2>&1
    # End should now be 10:30, length should be 1h30m = 5400s
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:30:00	work	5400	0'
}

test_extend_before_old_end() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" extend at 2026-01-01T09:30:00
}

test_extend_before_old_end_message() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "Cannot shrink" "$CLK_SCRIPT" extend at 2026-01-01T09:30:00
}

test_extend_no_done_records() {
    clk_test__assert_exit 5 "$CLK_SCRIPT" extend at 2026-01-01T10:00:00
}

test_extend_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" extend at 2026-01-01T10:30:00 2>&1)"
    clk_test__assert_output_contains "Extended session" printf '%s' "$output" &&
    clk_test__assert_output_contains "30m" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-01-01 10:30" printf '%s' "$output"
}

test_extend_creates_undo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    "$CLK_SCRIPT" extend at 2026-01-01T10:30:00 >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: extend should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_extend_preserves_break() {
    # Extend should preserve existing break time
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" add-break 10 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" extend at 2026-01-01T10:30:00 >/dev/null 2>&1
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local break_secs length_secs
    break_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f6)"
    length_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f5)"
    clk_test__assert_equals "600" "$break_secs" "extend preserves break" &&
    # length = old_length (3000) + 30min (1800) = 4800
    # old_length = (10:00-09:00)*60 - 600 = 3000
    clk_test__assert_equals "4800" "$length_secs" "extend correct length with break"
}

test_extend_with_active_present() {
    # extend should work even when active sessions exist
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" extend at 2026-01-01T10:30:00
}

test_extend_tag_extends_last_for_that_tag() {
    # Two completed sessions; extend <tag> should target the matching one
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out play at 2026-01-01T11:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" extend work at 2026-01-01T10:30:00 >/dev/null 2>&1
    # work record should be extended; play record unchanged
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local work_end play_end
    work_end="$(grep 'work' "$log_file" | cut -d"$(printf '\t')" -f3)"
    play_end="$(grep 'play' "$log_file" | cut -d"$(printf '\t')" -f3)"
    clk_test__assert_equals "2026-01-01T10:30:00" "$work_end" "extend tag targets correct record" &&
    clk_test__assert_equals "2026-01-01T11:00:00" "$play_end" "extend tag leaves other records unchanged"
}

test_extend_tag_no_done_records() {
    # Error when tag has no completed sessions
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 5 "$CLK_SCRIPT" extend play at 2026-01-01T10:30:00
}

test_extend_tag_active_session_errors() {
    # Error when specified tag has an active session
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in work at 2026-01-01T10:30:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" extend work at 2026-01-01T11:00:00
}

test_extend_tag_active_session_message() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in work at 2026-01-01T10:30:00 >/dev/null 2>&1
    clk_test__assert_output_contains "currently active" "$CLK_SCRIPT" extend work at 2026-01-01T11:00:00
}

test_extend_by_shifts_end_time() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" extend by 30 >/dev/null 2>&1
    # End should now be 10:30, length should be 1h30m = 5400s
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:30:00	work	5400	0'
}

test_extend_by_with_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out play at 2026-01-01T11:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" extend work by 15 >/dev/null 2>&1
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local work_end play_end
    work_end="$(grep 'work' "$log_file" | cut -d"$(printf '\t')" -f3)"
    play_end="$(grep 'play' "$log_file" | cut -d"$(printf '\t')" -f3)"
    clk_test__assert_equals "2026-01-01T10:15:00" "$work_end" "extend by tag shifts correct record" &&
    clk_test__assert_equals "2026-01-01T11:00:00" "$play_end" "extend by leaves other records unchanged"
}

#####################################################################
# Tests — clk remove (integration)
#####################################################################

test_remove_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" remove >/dev/null 2>&1
    local count
    count="$(awk -F'\t' '/^[^#]/ && NF>0' "$CLK_TEST_DIR/clk/clk.tsv" | wc -l | tr -d ' ')"
    clk_test__assert_equals "0" "$count" "remove deletes last record"
}

test_remove_active_record() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" remove >/dev/null 2>&1
    local count
    count="$(awk -F'\t' '/^[^#]/ && NF>0' "$CLK_TEST_DIR/clk/clk.tsv" | wc -l | tr -d ' ')"
    clk_test__assert_equals "0" "$count" "remove deletes active record"
}

test_remove_empty_log() {
    clk_test__assert_exit 5 "$CLK_SCRIPT" remove
}

test_remove_empty_log_message() {
    clk_test__assert_output_contains "No records to remove" "$CLK_SCRIPT" remove
}

test_remove_shows_removed_record() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" remove 2>&1)"
    clk_test__assert_output_contains "Removed record" printf '%s' "$output" &&
    clk_test__assert_output_contains "work" printf '%s' "$output"
}

test_remove_creates_undo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    "$CLK_SCRIPT" remove >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: remove should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_remove_alias_pop() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" pop
}

test_remove_preserves_other_records() {
    "$CLK_SCRIPT" in a at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out a at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in b at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out b at 2026-01-01T11:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" remove >/dev/null 2>&1
    # Only 'a' should remain
    local count
    count="$(awk -F'\t' '/^[^#]/ && NF>0' "$CLK_TEST_DIR/clk/clk.tsv" | wc -l | tr -d ' ')"
    clk_test__assert_equals "1" "$count" "remove preserves other records" &&
    clk_test__assert_log_line 1 'done.*a	3600'
}

#####################################################################
# Tests — clk undo (integration)
#####################################################################

test_undo_basic() {
    # mutate + undo → log matches pre-mutate state
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    local pre_mutate
    pre_mutate="$(cat "$CLK_TEST_DIR/clk/clk.tsv")"
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    local post_undo
    post_undo="$(cat "$CLK_TEST_DIR/clk/clk.tsv")"
    clk_test__assert_equals "$pre_mutate" "$post_undo" "undo restores pre-mutate state"
}

test_undo_nothing() {
    # No prior mutation → "Nothing to undo"
    # Ensure no .undo file exists (fresh log)
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    clk_test__assert_output_contains "Nothing to undo" "$CLK_SCRIPT" undo
}

test_undo_nothing_exits_0() {
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    clk_test__assert_exit 0 "$CLK_SCRIPT" undo
}

test_undo_shows_diff() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" undo 2>&1)"
    # Should show the done record being removed and active restored
    clk_test__assert_output_contains "Undone" printf '%s' "$output" &&
    clk_test__assert_output_contains "redo" printf '%s' "$output"
}

test_undo_creates_redo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.redo" ]; then
        printf 'FAIL: undo should create .redo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_undo_diff_shows_removed() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" undo 2>&1)"
    # The active record should appear as removed (−)
    if ! printf '%s' "$output" | grep -q '−.*work'; then
        printf 'FAIL: undo diff should show removed record\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_undo_diff_shows_restored() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" undo 2>&1)"
    # The active record should appear as restored (+)
    if ! printf '%s' "$output" | grep -q '+.*work.*active'; then
        printf 'FAIL: undo diff should show restored active record\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Tests — clk redo (integration)
#####################################################################

test_redo_basic() {
    # mutate + undo + redo → log matches post-mutate state
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    local post_mutate
    post_mutate="$(cat "$CLK_TEST_DIR/clk/clk.tsv")"
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    "$CLK_SCRIPT" redo >/dev/null 2>&1
    local post_redo
    post_redo="$(cat "$CLK_TEST_DIR/clk/clk.tsv")"
    clk_test__assert_equals "$post_mutate" "$post_redo" "redo restores post-mutate state"
}

test_redo_nothing() {
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.redo"
    clk_test__assert_output_contains "Nothing to redo" "$CLK_SCRIPT" redo
}

test_redo_nothing_exits_0() {
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.redo"
    clk_test__assert_exit 0 "$CLK_SCRIPT" redo
}

test_redo_shows_diff() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" redo 2>&1)"
    clk_test__assert_output_contains "Redone" printf '%s' "$output" &&
    clk_test__assert_output_contains "undo" printf '%s' "$output"
}

test_redo_creates_undo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    "$CLK_SCRIPT" redo >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: redo should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_undo_redo_roundtrip() {
    # in → out → undo → redo → undo → check state matches after first undo
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    local after_undo
    after_undo="$(cat "$CLK_TEST_DIR/clk/clk.tsv")"
    "$CLK_SCRIPT" redo >/dev/null 2>&1
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    local after_second_undo
    after_second_undo="$(cat "$CLK_TEST_DIR/clk/clk.tsv")"
    clk_test__assert_equals "$after_undo" "$after_second_undo" "undo/redo/undo roundtrip"
}

test_undo_overwrites_on_new_mutation() {
    # undo state should be overwritten by the next mutation
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Now mutate again — this should overwrite .undo
    "$CLK_SCRIPT" in play at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Undo should undo the 'in play', not the 'out work'
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    local log_content
    log_content="$(cat "$CLK_TEST_DIR/clk/clk.tsv")"
    # Should have done work record but no active play
    if printf '%s' "$log_content" | grep -q 'active.*play'; then
        printf 'FAIL: undo should have removed play, not work\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$log_content" | grep -q 'done.*work'; then
        printf 'FAIL: done work record should still exist\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_undo_clears_redo() {
    # After undo, a new mutation should clear .redo
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" undo >/dev/null 2>&1
    # .redo should exist now
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.redo" ]; then
        printf 'FAIL: .redo should exist after undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    # Now mutate — should clear .redo
    "$CLK_SCRIPT" in play at 2026-01-01T09:00:00 >/dev/null 2>&1
    if [ -f "${CLK_TEST_DIR}/clk/clk.tsv.redo" ]; then
        printf 'FAIL: .redo should be cleared after new mutation\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Test list
#####################################################################

CLK_TESTS_MUTATION=(
    # clk add (session)
    test_add_session_basic
    test_add_session_with_description
    test_add_session_creates_undo
    test_add_session_ordering_with_active
    test_add_session_confirmation_output
    test_add_session_missing_for
    test_add_session_numeric_tag_rejected
    test_add_session_alias_a
    test_add_time_alias_a
    test_add_session_simplified_timestamp_no_seconds

    # clk add (time to active)
    test_add_time_basic
    test_add_time_implicit_tag
    test_add_time_implicit_tag_correct
    test_add_time_ambiguous_tag
    test_add_time_confirmation_output
    test_add_time_creates_undo
    test_add_time_no_active

    # clk add-break (integration)
    test_add_break_basic
    test_add_break_accumulates
    test_add_break_while_paused
    test_add_break_while_paused_message
    test_add_break_with_to_tag
    test_add_break_alias_ab
    test_add_break_confirmation_output
    test_add_break_creates_undo
    test_add_break_missing_minutes

    # clk extend (integration)
    test_extend_basic
    test_extend_before_old_end
    test_extend_before_old_end_message
    test_extend_no_done_records
    test_extend_confirmation_output
    test_extend_creates_undo
    test_extend_preserves_break
    test_extend_with_active_present
    test_extend_tag_extends_last_for_that_tag
    test_extend_tag_no_done_records
    test_extend_tag_active_session_errors
    test_extend_tag_active_session_message
    test_extend_by_shifts_end_time
    test_extend_by_with_tag

    # clk remove (integration)
    test_remove_basic
    test_remove_active_record
    test_remove_empty_log
    test_remove_empty_log_message
    test_remove_shows_removed_record
    test_remove_creates_undo
    test_remove_alias_pop
    test_remove_preserves_other_records

    # clk undo (integration)
    test_undo_basic
    test_undo_nothing
    test_undo_nothing_exits_0
    test_undo_shows_diff
    test_undo_creates_redo
    test_undo_diff_shows_removed
    test_undo_diff_shows_restored

    # clk redo (integration)
    test_redo_basic
    test_redo_nothing
    test_redo_nothing_exits_0
    test_redo_shows_diff
    test_redo_creates_undo
    test_undo_redo_roundtrip
    test_undo_overwrites_on_new_mutation
    test_undo_clears_redo
)
