#!/usr/bin/env bash
# clk-test-view.bash — integration tests for view and script invocation
#
# Sourced by clk-test; do not run directly.
# Defines: CLK_TESTS_VIEW (array of test function names)

#####################################################################
# Tests — clk script invocation (no-args, help, unknown command)
#####################################################################

test_script_no_args_shows_synopsis() {
    clk_test__assert_output_contains "clk [help]" "$CLK_SCRIPT"
}

test_script_no_args_exits_0() {
    clk_test__assert_exit 0 "$CLK_SCRIPT"
}

test_script_unknown_command() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" "nosuchcommand"
}

test_script_unknown_command_message() {
    clk_test__assert_output_contains "Unknown command" "$CLK_SCRIPT" "nosuchcommand"
}

#####################################################################
# Tests — clk view (integration)
#####################################################################

# Helper: populate a test log with several completed sessions across dates
_view_setup_multi_day() {
    # 2026-03-18: 2h dev, 1h pm
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-18T13:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-18T14:00:00' >/dev/null 2>&1
    # 2026-03-19: 1h30m dev, 30m admin
    "$CLK_SCRIPT" in dev at '2026-03-19T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-19T11:30:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in admin at '2026-03-19T14:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out admin at '2026-03-19T14:30:00' >/dev/null 2>&1
}

test_view_from_until() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:30:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1

    local output
    output="$("$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' 2>&1)"
    clk_test__assert_output_contains "TOTAL" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' &&
    clk_test__assert_output_contains "dev" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' &&
    clk_test__assert_output_contains "pm" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' &&
    clk_test__assert_output_contains "150" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59'
}

test_view_from_until_range_desc() {
    "$CLK_SCRIPT" in dev at '2026-01-15T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-01-15T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "2026-01-15 00:00" "$CLK_SCRIPT" view from '2026-01-15T00:00:00' until '2026-01-15T23:59:59'
}

test_view_from_until_correct_totals() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:30:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1

    clk_test__assert_output_contains "2.50h" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59'
}

test_view_from_until_percentages() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:30:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1

    clk_test__assert_output_contains "60.00%" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' &&
    clk_test__assert_output_contains "40.00%" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59'
}

test_view_past_days() {
    _view_setup_multi_day
    # "past 3 days before <anchor>" should capture both days
    clk_test__assert_output_contains "dev" "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' &&
    clk_test__assert_output_contains "pm" "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' &&
    clk_test__assert_output_contains "admin" "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00'
}

test_view_past_hours() {
    "$CLK_SCRIPT" in dev at '2026-03-19T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-19T11:00:00' >/dev/null 2>&1
    # 2 hours before noon should capture the 10-11 session
    clk_test__assert_output_contains "dev" "$CLK_SCRIPT" view past 2 hours before '2026-03-19T12:00:00'
}

test_view_past_weeks() {
    _view_setup_multi_day
    clk_test__assert_output_contains "TOTAL" "$CLK_SCRIPT" view past 1 week before '2026-03-20T00:00:00'
}

test_view_past_singular() {
    # --- RATIONALE: Plurality leniency in view ---
    "$CLK_SCRIPT" in dev at '2026-03-19T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-19T11:00:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past 1 day before '2026-03-20T00:00:00'
}

test_view_past_plural() {
    "$CLK_SCRIPT" in dev at '2026-03-19T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-19T11:00:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past 1 days before '2026-03-20T00:00:00'
}

test_view_past_default_n() {
    # "past hours" without a number defaults to 1
    "$CLK_SCRIPT" in dev at '2026-03-19T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-19T11:30:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past hours before '2026-03-19T12:00:00'
}

test_view_before_timestamp() {
    _view_setup_multi_day
    # Anchored at 2026-03-19T15:00:00, looking back 2 days
    # Should see the 03-18 and 03-19 sessions
    clk_test__assert_output_contains "dev" "$CLK_SCRIPT" view past 2 days before '2026-03-19T15:00:00' &&
    clk_test__assert_output_contains "admin" "$CLK_SCRIPT" view past 2 days before '2026-03-19T15:00:00'
}

test_view_before_minus() {
    "$CLK_SCRIPT" in dev at '2026-03-19T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-19T11:00:00' >/dev/null 2>&1
    # This uses wallclock-relative "before minus", so we can only test it doesn't error
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past 1 week before minus 60
}

test_view_not_blocked_by_active() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in active-task at '2026-03-20T14:00:00' >/dev/null 2>&1
    # view should succeed even with an active session
    clk_test__assert_exit 0 "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59'
}

test_view_excludes_active_from_totals() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in active-task at '2026-03-20T14:00:00' >/dev/null 2>&1
    # Total should only be 60 minutes (1h dev), not include active-task
    clk_test__assert_output_contains "60" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59'
}

test_view_active_note() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in active-task at '2026-03-20T14:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "1 active session(s) not included" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59'
}

test_view_no_active_no_note() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' 2>&1)"
    if printf '%s' "$output" | grep -qF "active session(s)"; then
        printf 'FAIL: should not show active note when no active sessions\n'
        printf '  actual output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_empty_range() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    # Query a range that has no sessions
    clk_test__assert_output_contains "No completed sessions" \
        "$CLK_SCRIPT" view from '2026-03-15T00:00:00' until '2026-03-15T23:59:59'
}

test_view_today() {
    # Today is dynamic, so just verify it exits 0 and shows the header
    clk_test__assert_exit 0 "$CLK_SCRIPT" view today &&
    clk_test__assert_output_contains "Today" "$CLK_SCRIPT" view today
}

test_view_yesterday() {
    clk_test__assert_exit 0 "$CLK_SCRIPT" view yesterday &&
    clk_test__assert_output_contains "Yesterday" "$CLK_SCRIPT" view yesterday
}

test_view_sorted_by_time() {
    # Tags should be sorted by time descending (most time first)
    "$CLK_SCRIPT" in small at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out small at '2026-03-20T09:30:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in big at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out big at '2026-03-20T12:00:00' >/dev/null 2>&1

    local output
    output="$("$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' 2>&1)"
    # "big" should appear before "small" in the output (sorted descending by seconds)
    local big_pos small_pos
    big_pos="$(printf '%s' "$output" | grep -n "big" | head -1 | cut -d: -f1)"
    small_pos="$(printf '%s' "$output" | grep -n "small" | head -1 | cut -d: -f1)"
    if [ "$big_pos" -ge "$small_pos" ]; then
        printf 'FAIL: "big" should appear before "small" (sorted desc by time)\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_missing_args() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view
}

test_view_unknown_mode() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view foobar
}

test_view_past_missing_unit() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view past 3
}

test_view_past_bad_unit() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view past 3 fortnights
}

test_view_from_missing_until() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view from '2026-03-20T00:00:00'
}

test_view_from_bad_timestamp() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view from 'nope' until '2026-03-20T23:59:59'
}

test_view_alias_v() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-15T12:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" v from 2026-01-15T00:00:00 until 2026-01-15T23:59:59
}

test_view_alias_v_today() {
    clk_test__assert_exit 0 "$CLK_SCRIPT" v today
}

test_view_from_simplified_timestamp() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-15T12:00:00 >/dev/null 2>&1
    # Use yyyy-mm-ddTHH:MM format (no seconds)
    clk_test__assert_exit 0 "$CLK_SCRIPT" view from 2026-01-15T00:00 until 2026-01-15T23:59
}

test_view_before_simplified_timestamp() {
    "$CLK_SCRIPT" add work for 60 at 2026-01-15T12:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past 1 day before 2026-01-16T00:00
}

#####################################################################
# Tests — clk view month(s) unit
#####################################################################

test_view_past_months() {
    "$CLK_SCRIPT" in dev at '2026-02-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-02-20T11:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "dev" "$CLK_SCRIPT" view past 2 months before '2026-03-20T00:00:00'
}

test_view_past_month_singular() {
    "$CLK_SCRIPT" in dev at '2026-03-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-01T10:00:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past 1 month before '2026-03-20T00:00:00'
}

test_view_past_month_range_desc() {
    "$CLK_SCRIPT" in dev at '2026-03-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-01T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "Past 1 month" "$CLK_SCRIPT" view past 1 month before '2026-03-20T00:00:00'
}

test_view_past_months_plural_range_desc() {
    "$CLK_SCRIPT" in dev at '2026-01-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-01-01T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "Past 3 months" "$CLK_SCRIPT" view past 3 months before '2026-03-20T00:00:00'
}

#####################################################################
# Tests — clk view from ... to ... (alias for until)
#####################################################################

test_view_from_to() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "dev" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' to '2026-03-20T23:59:59'
}

test_view_from_to_exit_0() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view from '2026-03-20T00:00:00' to '2026-03-20T23:59:59'
}

test_view_from_to_totals() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "90" "$CLK_SCRIPT" view from '2026-03-20T00:00:00' to '2026-03-20T23:59:59'
}

#####################################################################
# Tests — clk view for <tag> (tag filter)
#####################################################################

test_view_for_tag_filter() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "dev" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for dev
}

test_view_for_tag_excludes_other() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for dev 2>&1)"
    if printf '%s' "$output" | grep -qw "pm"; then
        printf 'FAIL: "pm" should not appear when filtering for "dev"\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_for_tag_correct_total() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1
    # Filtering for dev: should show 60 minutes total (not 120)
    clk_test__assert_output_contains "1.00h" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for dev
}

test_view_for_tag_shows_filter_label() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "Filtered by tag: dev" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for dev
}

test_view_for_tag_with_past() {
    "$CLK_SCRIPT" in exercise at '2026-03-19T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in work at '2026-03-19T13:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-03-19T15:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "exercise" \
        "$CLK_SCRIPT" view past 1 day before '2026-03-20T00:00:00' for exercise
}

test_view_for_tag_no_match() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "No completed sessions" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for nonexistent
}

test_view_for_missing_tag() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view today for
}

test_view_for_tag_no_active_note_other_tag() {
    # Active session for "other-tag" should not produce the active note
    # when filtering for "dev"
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in other-tag at '2026-03-20T14:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for dev 2>&1)"
    if printf '%s' "$output" | grep -qF "active session(s)"; then
        printf 'FAIL: should not show active note when active session is for a different tag\n'
        printf '  actual output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_for_tag_active_note_same_tag() {
    # Active session for the filtered tag SHOULD show the note
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in dev at '2026-03-20T14:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "1 active session(s) not included" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for dev
}

#####################################################################
# Tests — clk view by <day|week> (grouped bar chart)
#####################################################################

test_view_by_day() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day 2>&1)"
    # Should show both dates and minute values
    if ! printf '%s' "$output" | grep -q "2026-03-18" || ! printf '%s' "$output" | grep -q "2026-03-19"; then
        printf 'FAIL: expected both dates in bar chart output\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_by_day_shows_minutes() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "60m" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_shows_bars() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    # Bar chart should contain block characters
    clk_test__assert_output_contains "█" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_week() {
    # Sessions in two different weeks
    "$CLK_SCRIPT" in work at '2026-03-09T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-03-09T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in work at '2026-03-16T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-03-16T12:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view past 2 weeks before '2026-03-20T00:00:00' for work by week 2>&1)"
    # Should show week labels (Monday dates)
    if ! printf '%s' "$output" | grep -q "2026-03-09" || ! printf '%s' "$output" | grep -q "2026-03-16"; then
        printf 'FAIL: expected both week-start dates in bar chart output\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_by_week_minutes() {
    "$CLK_SCRIPT" in work at '2026-03-16T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-03-16T12:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "180m" \
        "$CLK_SCRIPT" view past 1 week before '2026-03-20T00:00:00' for work by week
}

test_view_by_requires_for() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view today by day
}

test_view_by_requires_for_message() {
    clk_test__assert_output_contains "requires a tag filter" "$CLK_SCRIPT" view today by day
}

test_view_by_bad_group() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view today for dev by year
}

test_view_by_day_shows_header() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "by day" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_from_to() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    # Use 'to' instead of 'until' with 'for' and 'by'
    clk_test__assert_exit 0 \
        "$CLK_SCRIPT" view from '2026-03-17T00:00:00' to '2026-03-20T00:00:00' for exercise by day
}

#####################################################################
# Test list
#####################################################################

CLK_TESTS_VIEW=(
    # script invocation
    test_script_no_args_shows_synopsis
    test_script_no_args_exits_0
    test_script_unknown_command
    test_script_unknown_command_message

    # clk view (integration)
    test_view_from_until
    test_view_from_until_range_desc
    test_view_from_until_correct_totals
    test_view_from_until_percentages
    test_view_past_days
    test_view_past_hours
    test_view_past_weeks
    test_view_past_singular
    test_view_past_plural
    test_view_past_default_n
    test_view_before_timestamp
    test_view_before_minus
    test_view_not_blocked_by_active
    test_view_excludes_active_from_totals
    test_view_active_note
    test_view_no_active_no_note
    test_view_empty_range
    test_view_today
    test_view_yesterday
    test_view_sorted_by_time
    test_view_missing_args
    test_view_unknown_mode
    test_view_past_missing_unit
    test_view_past_bad_unit
    test_view_from_missing_until
    test_view_from_bad_timestamp
    test_view_alias_v
    test_view_alias_v_today
    test_view_from_simplified_timestamp
    test_view_before_simplified_timestamp

    # clk view past month(s)
    test_view_past_months
    test_view_past_month_singular
    test_view_past_month_range_desc
    test_view_past_months_plural_range_desc

    # clk view from ... to ... (alias for until)
    test_view_from_to
    test_view_from_to_exit_0
    test_view_from_to_totals

    # clk view for <tag>
    test_view_for_tag_filter
    test_view_for_tag_excludes_other
    test_view_for_tag_correct_total
    test_view_for_tag_shows_filter_label
    test_view_for_tag_with_past
    test_view_for_tag_no_match
    test_view_for_missing_tag
    test_view_for_tag_no_active_note_other_tag
    test_view_for_tag_active_note_same_tag

    # clk view by <day|week>
    test_view_by_day
    test_view_by_day_shows_minutes
    test_view_by_day_shows_bars
    test_view_by_week
    test_view_by_week_minutes
    test_view_by_requires_for
    test_view_by_requires_for_message
    test_view_by_bad_group
    test_view_by_day_shows_header
    test_view_by_day_from_to
)
