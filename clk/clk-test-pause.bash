#!/usr/bin/env bash
# clk-test-pause.bash — integration tests for pause, resume, unpause, switch,
#                        out-while-paused, and pause/resume cycles
#
# Sourced by clk-test; do not run directly.
# Defines: CLK_TESTS_PAUSE (array of test function names)

#####################################################################
# Tests — clk pause (integration)
#####################################################################

test_pause_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    # PAUSED_AT (field 7) should be set to an epoch
    clk_test__assert_log_line 1 '^active	2026-01-01T09:00:00		work		0	[0-9]'
}

test_pause_already_paused() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    clk_test__assert_exit 5 "$CLK_SCRIPT" pause
}

test_pause_already_paused_message() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    clk_test__assert_output_contains "already paused" "$CLK_SCRIPT" pause
}

test_pause_implicit_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" pause
}

test_pause_explicit_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" pause work
}

test_pause_ambiguous_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" pause
}

test_pause_minus() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause minus 10 >/dev/null 2>&1
    # PAUSED_AT should be now_epoch - 600
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local paused_at
    paused_at="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f7)"
    local now_epoch expected_epoch
    now_epoch="$(date +%s)"
    expected_epoch=$(( now_epoch - 600 ))
    local diff=$(( paused_at - expected_epoch ))
    if [ "$diff" -lt 0 ]; then diff=$(( -diff )); fi
    if [ "$diff" -gt 5 ]; then
        printf 'FAIL: pause minus 10 epoch off by %d seconds\n' "$diff"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_pause_at() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause at 2026-01-01T10:30:00 >/dev/null 2>&1
    # PAUSED_AT should be the epoch for 2026-01-01T10:30:00
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local paused_at
    paused_at="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f7)"
    # Convert 2026-01-01T10:30:00 to epoch for comparison
    CLK_SOURCED=1 source "$CLK_SCRIPT"
    clk__ensure_log >/dev/null 2>&1
    local expected_epoch
    expected_epoch="$(clk__to_epoch "2026-01-01T10:30:00")"
    clk_test__assert_equals "$expected_epoch" "$paused_at" "pause at sets correct epoch"
}

test_pause_at_with_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" pause work at 2026-01-01T10:00:00
}

test_pause_at_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "2026-01-01 10:30" "$CLK_SCRIPT" pause at 2026-01-01T10:30:00
}

test_pause_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "paused at" "$CLK_SCRIPT" pause &&
    "$CLK_SCRIPT" in play at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "Active work so far" "$CLK_SCRIPT" pause play
}

test_pause_creates_undo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: pause should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_pause_no_active() {
    clk_test__assert_exit 5 "$CLK_SCRIPT" pause
}

test_pause_alias_p() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" p
}

#####################################################################
# Tests — clk resume (integration)
#####################################################################

test_resume_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    "$CLK_SCRIPT" resume >/dev/null 2>&1
    # PAUSED_AT (field 7) should be cleared, BREAK_SECS (field 6) should be > 0 or == 0
    # and the record should be active with no paused_at
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local last_line paused_at
    last_line="$(tail -1 "$log_file")"
    paused_at="$(printf '%s' "$last_line" | cut -d"$(printf '\t')" -f7)"
    if [ -n "$paused_at" ]; then
        printf 'FAIL: PAUSED_AT should be cleared after resume, got "%s"\n' "$paused_at"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_resume_adds_break() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    sleep 1
    "$CLK_SCRIPT" resume >/dev/null 2>&1
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local break_secs
    break_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f6)"
    if [ "$break_secs" -lt 1 ]; then
        printf 'FAIL: resume should add break time, got %s\n' "$break_secs"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_resume_not_paused() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 5 "$CLK_SCRIPT" resume
}

test_resume_not_paused_message() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "not paused" "$CLK_SCRIPT" resume
}

test_resume_minus() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    sleep 1
    "$CLK_SCRIPT" resume minus 0 >/dev/null 2>&1
    # Should succeed
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local paused_at
    paused_at="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f7)"
    if [ -n "$paused_at" ]; then
        printf 'FAIL: PAUSED_AT should be cleared after resume minus\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_resume_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" resume 2>&1)"
    clk_test__assert_output_contains "resumed at" printf '%s' "$output" &&
    clk_test__assert_output_contains "This pause" printf '%s' "$output" &&
    clk_test__assert_output_contains "Total break" printf '%s' "$output"
}

test_resume_alias_r() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" p >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" r
}

#####################################################################
# Tests — clk unpause (integration)
#####################################################################

test_unpause_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    "$CLK_SCRIPT" unpause >/dev/null 2>&1
    # PAUSED_AT should be cleared
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local paused_at
    paused_at="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f7)"
    if [ -n "$paused_at" ]; then
        printf 'FAIL: PAUSED_AT should be cleared after unpause\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_unpause_no_break_added() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    sleep 1
    "$CLK_SCRIPT" unpause >/dev/null 2>&1
    # BREAK_SECS should still be 0
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local break_secs
    break_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f6)"
    clk_test__assert_equals "0" "$break_secs" "unpause should not add break time"
}

test_unpause_not_paused() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 5 "$CLK_SCRIPT" unpause
}

test_unpause_not_paused_message() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "not paused" "$CLK_SCRIPT" unpause
}

test_unpause_confirmation() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    clk_test__assert_output_contains "Pause cancelled" "$CLK_SCRIPT" unpause
}

test_unpause_explicit_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause work >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" unpause work
}

#####################################################################
# Tests — clk switch (integration)
#####################################################################

test_switch_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" switch play at 2026-01-01T10:00:00 >/dev/null 2>&1
    # work should be a done record, play should be active
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local line2 line3
    line2="$(awk 'NR==2' "$log_file")"
    line3="$(awk 'NR==3' "$log_file")"
    if ! printf '%s' "$line2" | grep -q '^done.*work'; then
        printf 'FAIL: line 2 should be done work record\n  actual: %s\n' "$line2"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$line3" | grep -q '^active.*play'; then
        printf 'FAIL: line 3 should be active play record\n  actual: %s\n' "$line3"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_switch_with_from() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    "$CLK_SCRIPT" switch dev from work at 2026-01-01T10:00:00 >/dev/null 2>&1
    # work should be done, play and dev should be active
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local done_count active_count
    done_count="$(awk -F'\t' '$1=="done"' "$log_file" | wc -l | tr -d ' ')"
    active_count="$(awk -F'\t' '$1=="active"' "$log_file" | wc -l | tr -d ' ')"
    clk_test__assert_equals "1" "$done_count" "switch from: one done record" &&
    clk_test__assert_equals "2" "$active_count" "switch from: two active records"
}

test_switch_implicit_from() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" switch play at 2026-01-01T10:00:00
}

test_switch_ambiguous_from() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" switch dev at 2026-01-01T10:00:00
}

test_switch_with_description() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" switch play at 2026-01-01T10:00:00 on finished task >/dev/null 2>&1
    # The done record for work should have the description
    clk_test__assert_log_line 2 'finished task'
}

test_switch_same_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" switch work at 2026-01-01T10:00:00
}

test_switch_creates_single_undo() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    \rm -f "${CLK_TEST_DIR}/clk/clk.tsv.undo"
    "$CLK_SCRIPT" switch play at 2026-01-01T10:00:00 >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: switch should create .undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_switch_missing_new_tag() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" switch
}

test_switch_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" switch play at 2026-01-01T10:00:00 2>&1)"
    clk_test__assert_output_contains "Recorded session" printf '%s' "$output" &&
    clk_test__assert_output_contains "Started session" printf '%s' "$output"
}

#####################################################################
# Tests — out while paused (integration)
#####################################################################

test_out_while_paused() {
    # Use real "now" for both pause and out so timing is consistent
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    sleep 1
    "$CLK_SCRIPT" out work >/dev/null 2>&1
    # Should succeed — pause auto-finalized
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local last_line status break_secs
    last_line="$(tail -1 "$log_file")"
    status="$(printf '%s' "$last_line" | cut -d"$(printf '\t')" -f1)"
    break_secs="$(printf '%s' "$last_line" | cut -d"$(printf '\t')" -f6)"
    clk_test__assert_equals "done" "$status" "out while paused creates done record" &&
    if [ "$break_secs" -lt 1 ]; then
        printf 'FAIL: out while paused should have break_secs > 0, got %s\n' "$break_secs"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_out_while_paused_shows_break() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    sleep 1
    clk_test__assert_output_contains "break" "$CLK_SCRIPT" out work
}

#####################################################################
# Tests — pause/resume cycle with out (integration)
#####################################################################

test_pause_resume_then_out() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" pause >/dev/null 2>&1
    sleep 1
    "$CLK_SCRIPT" resume >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T11:00:00 >/dev/null 2>&1
    # Should have break time from the pause, and length should be reduced
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local break_secs length_secs
    break_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f6)"
    length_secs="$(tail -1 "$log_file" | cut -d"$(printf '\t')" -f5)"
    if [ "$break_secs" -lt 1 ]; then
        printf 'FAIL: break_secs should be > 0 after pause/resume, got %s\n' "$break_secs"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    # length should be (2h = 7200) - break_secs
    local expected_length=$(( 7200 - break_secs ))
    clk_test__assert_equals "$expected_length" "$length_secs" "length = total - break after pause/resume"
}

#####################################################################
# Test list
#####################################################################

CLK_TESTS_PAUSE=(
    # clk pause (integration)
    test_pause_basic
    test_pause_already_paused
    test_pause_already_paused_message
    test_pause_implicit_tag
    test_pause_explicit_tag
    test_pause_ambiguous_tag
    test_pause_minus
    test_pause_at
    test_pause_at_with_tag
    test_pause_at_confirmation_output
    test_pause_confirmation_output
    test_pause_creates_undo
    test_pause_no_active
    test_pause_alias_p

    # clk resume (integration)
    test_resume_basic
    test_resume_adds_break
    test_resume_not_paused
    test_resume_not_paused_message
    test_resume_minus
    test_resume_confirmation_output
    test_resume_alias_r

    # clk unpause (integration)
    test_unpause_basic
    test_unpause_no_break_added
    test_unpause_not_paused
    test_unpause_not_paused_message
    test_unpause_confirmation
    test_unpause_explicit_tag

    # clk switch (integration)
    test_switch_basic
    test_switch_with_from
    test_switch_implicit_from
    test_switch_ambiguous_from
    test_switch_with_description
    test_switch_same_tag
    test_switch_creates_single_undo
    test_switch_missing_new_tag
    test_switch_confirmation_output

    # out while paused
    test_out_while_paused
    test_out_while_paused_shows_break

    # pause/resume cycle
    test_pause_resume_then_out
)
