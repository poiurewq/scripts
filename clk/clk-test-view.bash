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

test_view_by_without_for() {
    # by day should work without 'for <tag>' — aggregates all tags
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-18T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-18T12:00:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' by day
}

test_view_by_without_for_all_tags_header() {
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "All tags" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' by day
}

test_view_by_without_for_aggregates() {
    # 60m dev + 60m pm on same day → 120m total in that day bucket
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-18T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-18T12:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "120m" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' by day
}

test_view_by_bad_group() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view today for dev by fortnight
}

test_view_by_day_shows_header() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "by day" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_mean() {
    # Two days: 60m and 30m → mean = 45.0m
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "mean" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_median() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "median" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_stddev() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "stddev" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_skew() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "skew" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_values() {
    # 60m and 30m → mean = 45.0m, median = 45.0m
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "45.0m" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_week_stats() {
    "$CLK_SCRIPT" in work at '2026-03-09T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-03-09T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in work at '2026-03-16T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-03-16T12:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "mean" \
        "$CLK_SCRIPT" view past 2 weeks before '2026-03-20T00:00:00' for work by week
}

#####################################################################
# Tests — clk view all
#####################################################################

test_view_all() {
    "$CLK_SCRIPT" in dev at '2025-01-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2025-01-01T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T10:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view all 2>&1)"
    # Should show both tags from very different dates
    if ! printf '%s' "$output" | grep -q "dev" || ! printf '%s' "$output" | grep -q "pm"; then
        printf 'FAIL: expected both "dev" and "pm" in view all output\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_all_range_desc() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "All time" "$CLK_SCRIPT" view all
}

test_view_all_exit_0() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view all
}

test_view_all_empty_log() {
    clk_test__assert_output_contains "No completed sessions" "$CLK_SCRIPT" view all
}

test_view_all_for_tag() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "Filtered by tag: dev" "$CLK_SCRIPT" view all for dev
}

test_view_all_for_tag_by_day() {
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in dev at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-19T11:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view all for dev by day 2>&1)"
    if ! printf '%s' "$output" | grep -q "2026-03-18" || ! printf '%s' "$output" | grep -q "2026-03-19"; then
        printf 'FAIL: expected both dates in view all for dev by day\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Tests — clk view past year(s)
#####################################################################

test_view_past_years() {
    "$CLK_SCRIPT" in dev at '2025-06-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2025-06-01T11:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "dev" "$CLK_SCRIPT" view past 1 year before '2026-03-20T00:00:00'
}

test_view_past_year_singular() {
    "$CLK_SCRIPT" in dev at '2025-06-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2025-06-01T10:00:00' >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view past 1 year before '2026-03-20T00:00:00'
}

test_view_past_year_range_desc() {
    "$CLK_SCRIPT" in dev at '2025-06-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2025-06-01T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "Past 1 year" "$CLK_SCRIPT" view past 1 year before '2026-03-20T00:00:00'
}

test_view_past_years_plural_range_desc() {
    "$CLK_SCRIPT" in dev at '2024-01-01T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2024-01-01T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "Past 2 years" "$CLK_SCRIPT" view past 2 years before '2026-03-20T00:00:00'
}

#####################################################################
# Tests — clk view for <tag1|tag2> (multi-tag filter)
#####################################################################

test_view_multi_tag_filter() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in admin at '2026-03-20T13:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out admin at '2026-03-20T14:00:00' >/dev/null 2>&1
    # Filter for dev|pm → should show both, not admin
    local output
    output="$("$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for 'dev|pm' 2>&1)"
    if ! printf '%s' "$output" | grep -qw "dev" || ! printf '%s' "$output" | grep -qw "pm"; then
        printf 'FAIL: expected both "dev" and "pm" in multi-tag output\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_multi_tag_excludes_other() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in admin at '2026-03-20T13:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out admin at '2026-03-20T14:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for 'dev|pm' 2>&1)"
    if printf '%s' "$output" | grep -qw "admin"; then
        printf 'FAIL: "admin" should not appear when filtering for "dev|pm"\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_multi_tag_correct_total() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-20T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-20T12:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in admin at '2026-03-20T13:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out admin at '2026-03-20T14:00:00' >/dev/null 2>&1
    # dev (60m) + pm (60m) = 120m total, not 180m
    clk_test__assert_output_contains "2.00h" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for 'dev|pm'
}

test_view_multi_tag_shows_filter_label() {
    "$CLK_SCRIPT" in dev at '2026-03-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-20T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "Filtered by tag: dev, pm" \
        "$CLK_SCRIPT" view from '2026-03-20T00:00:00' until '2026-03-20T23:59:59' for 'dev|pm'
}

test_view_multi_tag_by_day() {
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-18T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-18T12:00:00' >/dev/null 2>&1
    # 60m + 60m = 120m on the same day
    clk_test__assert_output_contains "120m" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for 'dev|pm' by day
}

#####################################################################
# Tests — clk view by month
#####################################################################

test_view_by_month() {
    "$CLK_SCRIPT" in work at '2026-01-15T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-01-15T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in work at '2026-02-15T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-02-15T12:00:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view past 3 months before '2026-03-20T00:00:00' for work by month 2>&1)"
    if ! printf '%s' "$output" | grep -q "2026-01" || ! printf '%s' "$output" | grep -q "2026-02"; then
        printf 'FAIL: expected both month labels in by month output\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_by_month_minutes() {
    "$CLK_SCRIPT" in work at '2026-02-10T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-02-10T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in work at '2026-02-20T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-02-20T10:00:00' >/dev/null 2>&1
    # 120m + 60m = 180m total in Feb
    clk_test__assert_output_contains "180m" \
        "$CLK_SCRIPT" view past 2 months before '2026-03-20T00:00:00' for work by month
}

test_view_by_month_shows_header() {
    "$CLK_SCRIPT" in work at '2026-02-15T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out work at '2026-02-15T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "by month" \
        "$CLK_SCRIPT" view past 2 months before '2026-03-20T00:00:00' for work by month
}

test_view_by_month_without_for() {
    "$CLK_SCRIPT" in dev at '2026-02-15T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-02-15T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-02-15T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-02-15T12:00:00' >/dev/null 2>&1
    # Without for, aggregates all tags: 120m total
    clk_test__assert_output_contains "120m" \
        "$CLK_SCRIPT" view past 2 months before '2026-03-20T00:00:00' by month
}

#####################################################################
# Tests — clk view by session
#####################################################################

test_view_by_session() {
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in dev at '2026-03-18T14:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T15:30:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for dev by session 2>&1)"
    # Should show both session start timestamps (no seconds, space-separated)
    if ! printf '%s' "$output" | grep -q "2026-03-18 09:00" || ! printf '%s' "$output" | grep -q "2026-03-18 14:00"; then
        printf 'FAIL: expected both session timestamps in by session output\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_by_session_shows_minutes() {
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "1h 00m" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for dev by session
}

test_view_by_session_shows_header() {
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    clk_test__assert_output_contains "by session" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for dev by session
}

test_view_by_session_without_for() {
    "$CLK_SCRIPT" in dev at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at '2026-03-18T11:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at '2026-03-18T12:00:00' >/dev/null 2>&1
    # Without for: both sessions appear
    local output
    output="$("$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' by session 2>&1)"
    if ! printf '%s' "$output" | grep -q "1h 00m"; then
        printf 'FAIL: expected session duration in by session without for\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_view_by_day_from_to() {
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    # Use 'to' instead of 'until' with 'for' and 'by'
    clk_test__assert_exit 0 \
        "$CLK_SCRIPT" view from '2026-03-17T00:00:00' to '2026-03-20T00:00:00' for exercise by day
}

#####################################################################
# Tests — clk view stats total
#####################################################################

test_view_by_day_stats_total() {
    # Two days: 60m + 30m = 90m total
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "total" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_total_minutes() {
    # Two days: 60m + 30m = 90m total
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "90m" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_total_hours_minutes() {
    # Two days: 60m + 30m = 90m → 1h 30m
    "$CLK_SCRIPT" in exercise at '2026-03-18T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-18T10:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    clk_test__assert_output_contains "1h 30m" \
        "$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day
}

test_view_by_day_stats_total_under_60() {
    # Single day: 30m → no h:m conversion
    "$CLK_SCRIPT" in exercise at '2026-03-19T09:00:00' >/dev/null 2>&1
    "$CLK_SCRIPT" out exercise at '2026-03-19T09:30:00' >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" view past 3 days before '2026-03-20T00:00:00' for exercise by day 2>&1)"
    # Should have total with 30m but no h:m conversion
    if ! printf '%s' "$output" | grep -q "total.*30m"; then
        printf 'FAIL: expected total 30m in output\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if printf '%s' "$output" | grep "total" | grep -q "("; then
        printf 'FAIL: total under 60m should not have h:m conversion\n'
        printf '  output: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Tests — clk view -<n> day(s)/week(s)/month(s)
#####################################################################

# Helper: compute a timestamp at a given hour on the day at offset from today.
# Usage: _view_ts_at_day_offset <offset_days> <HH:MM:SS>
# e.g. _view_ts_at_day_offset 0 09:00:00  → today at 9am
#      _view_ts_at_day_offset -1 10:00:00 → yesterday at 10am
_view_ts_at_day_offset() {
    local offset="$1" time="$2"
    local day_epoch ts_date
    day_epoch="$(clk__midnight_epoch "$offset")"
    ts_date="$(clk__from_epoch "$day_epoch")"
    # ts_date is full ISO; extract just the date part and append the time
    printf '%s' "${ts_date%%T*}T${time}"
}

# Helper: compute a timestamp at a given hour on a day within the week at offset.
# Usage: _view_ts_at_week_offset <offset_weeks> <day_in_week_1_7> <HH:MM:SS>
# day_in_week: 1=Mon, 2=Tue, ... 7=Sun
_view_ts_at_week_offset() {
    local offset_weeks="$1" dow="$2" time="$3"
    local week_start_epoch day_epoch ts_date
    week_start_epoch="$(clk__week_start_epoch "$offset_weeks")"
    day_epoch=$(( week_start_epoch + (dow - 1) * 86400 ))
    ts_date="$(clk__from_epoch "$day_epoch")"
    printf '%s' "${ts_date%%T*}T${time}"
}

# Helper: compute a timestamp at a given day+hour within the month at offset.
# Usage: _view_ts_at_month_offset <offset_months> <day_of_month> <HH:MM:SS>
_view_ts_at_month_offset() {
    local offset_months="$1" dom="$2" time="$3"
    local month_start_epoch day_epoch ts_date
    month_start_epoch="$(clk__month_start_epoch "$offset_months")"
    day_epoch=$(( month_start_epoch + (dom - 1) * 86400 ))
    ts_date="$(clk__from_epoch "$day_epoch")"
    printf '%s' "${ts_date%%T*}T${time}"
}

test_view_offset_0_day() {
    # -0 day should behave like today
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset 0 09:00:00)"
    ts_out="$(_view_ts_at_day_offset 0 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Today" \
        "$CLK_SCRIPT" view -0 day
}

test_view_offset_0_days_plural() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset 0 09:00:00)"
    ts_out="$(_view_ts_at_day_offset 0 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" view -0 days
}

test_view_offset_1_day() {
    # -1 day should behave like yesterday
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -1 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Yesterday" \
        "$CLK_SCRIPT" view -1 day
}

test_view_offset_2_days() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -2 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "2 days ago" \
        "$CLK_SCRIPT" view -2 days
}

test_view_offset_day_shows_data() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -1 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "60" \
        "$CLK_SCRIPT" view -1 day
}

test_view_current_day() {
    # 'current' is alias for -0
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset 0 09:00:00)"
    ts_out="$(_view_ts_at_day_offset 0 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Today" \
        "$CLK_SCRIPT" view current day
}

test_view_offset_0_week() {
    # -0 week = this week (Mon-now); use Tuesday of current week
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset 0 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset 0 2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "This week" \
        "$CLK_SCRIPT" view -0 week
}

test_view_offset_1_week() {
    # -1 week = last week Mon-Sun; use Tuesday of last week
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset -1 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset -1 2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Last week" \
        "$CLK_SCRIPT" view -1 week
}

test_view_offset_2_weeks() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset -2 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset -2 2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "2 weeks ago" \
        "$CLK_SCRIPT" view -2 weeks
}

test_view_current_week() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset 0 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset 0 2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "This week" \
        "$CLK_SCRIPT" view current week
}

test_view_offset_week_shows_data() {
    # Last week, Tuesday, 2h session → 120m
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset -1 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset -1 2 11:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "120" \
        "$CLK_SCRIPT" view -1 week
}

test_view_offset_0_month() {
    # -0 month = this month; use 5th of current month
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset 0 5 09:00:00)"
    ts_out="$(_view_ts_at_month_offset 0 5 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "This month" \
        "$CLK_SCRIPT" view -0 month
}

test_view_offset_1_month() {
    # -1 month = last month; use 10th
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset -1 10 09:00:00)"
    ts_out="$(_view_ts_at_month_offset -1 10 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Last month" \
        "$CLK_SCRIPT" view -1 month
}

test_view_offset_2_months() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset -2 15 09:00:00)"
    ts_out="$(_view_ts_at_month_offset -2 15 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "2 months ago" \
        "$CLK_SCRIPT" view -2 months
}

test_view_current_month() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset 0 5 09:00:00)"
    ts_out="$(_view_ts_at_month_offset 0 5 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "This month" \
        "$CLK_SCRIPT" view current month
}

test_view_offset_month_shows_data() {
    # Last month, 15th, 2.5h session → 150m
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset -1 15 09:00:00)"
    ts_out="$(_view_ts_at_month_offset -1 15 11:30:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "150" \
        "$CLK_SCRIPT" view -1 month
}

test_view_offset_day_for_tag() {
    # -1 day with for <tag> filter
    local ts_in1 ts_out1 ts_in2 ts_out2
    ts_in1="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out1="$(_view_ts_at_day_offset -1 10:00:00)"
    ts_in2="$(_view_ts_at_day_offset -1 11:00:00)"
    ts_out2="$(_view_ts_at_day_offset -1 12:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in1" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out1" >/dev/null 2>&1
    "$CLK_SCRIPT" in pm at "$ts_in2" >/dev/null 2>&1
    "$CLK_SCRIPT" out pm at "$ts_out2" >/dev/null 2>&1
    clk_test__assert_output_contains "dev" \
        "$CLK_SCRIPT" view -1 day for dev
}

test_view_offset_week_by_day() {
    # -0 week with by day grouping; Mon and Tue of current week
    local ts_in1 ts_out1 ts_in2 ts_out2
    ts_in1="$(_view_ts_at_week_offset 0 1 09:00:00)"
    ts_out1="$(_view_ts_at_week_offset 0 1 10:00:00)"
    ts_in2="$(_view_ts_at_week_offset 0 2 09:00:00)"
    ts_out2="$(_view_ts_at_week_offset 0 2 10:30:00)"
    "$CLK_SCRIPT" in dev at "$ts_in1" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out1" >/dev/null 2>&1
    "$CLK_SCRIPT" in dev at "$ts_in2" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out2" >/dev/null 2>&1
    clk_test__assert_output_contains "by day" \
        "$CLK_SCRIPT" view -0 week for dev by day
}

test_view_offset_missing_unit() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view -1
}

test_view_offset_bad_unit() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view -1 fortnights
}

#####################################################################
# Tests — clk view through (multi-period ranges)
#####################################################################

test_view_through_weeks() {
    # -2 weeks through -1 week: data in last week should appear
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset -1 3 09:00:00)"
    ts_out="$(_view_ts_at_week_offset -1 3 11:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "120" \
        "$CLK_SCRIPT" view -2 weeks through -1 week
}

test_view_through_weeks_range_desc() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset -2 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset -2 2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "2 weeks ago through last week" \
        "$CLK_SCRIPT" view -2 weeks through -1 week
}

test_view_through_days() {
    # -3 days through -1 day: data 2 days ago should appear
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -2 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "60" \
        "$CLK_SCRIPT" view -3 days through -1 day
}

test_view_through_days_range_desc() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -2 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "2 days ago through yesterday" \
        "$CLK_SCRIPT" view -2 days through -1 day
}

test_view_through_months() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset -1 10 09:00:00)"
    ts_out="$(_view_ts_at_month_offset -1 10 10:30:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "90" \
        "$CLK_SCRIPT" view -2 months through -1 month
}

test_view_through_months_range_desc() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset -2 5 09:00:00)"
    ts_out="$(_view_ts_at_month_offset -2 5 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "2 months ago through last month" \
        "$CLK_SCRIPT" view -2 months through -1 month
}

test_view_through_current() {
    # -1 week through current week: should end at now
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset -1 3 09:00:00)"
    ts_out="$(_view_ts_at_week_offset -1 3 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Last week through this week" \
        "$CLK_SCRIPT" view -1 week through current week
}

test_view_through_with_for() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset -1 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset -1 2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "dev" \
        "$CLK_SCRIPT" view -2 weeks through -1 week for dev
}

test_view_through_with_by() {
    local ts_in1 ts_out1 ts_in2 ts_out2
    ts_in1="$(_view_ts_at_week_offset -2 2 09:00:00)"
    ts_out1="$(_view_ts_at_week_offset -2 2 10:00:00)"
    ts_in2="$(_view_ts_at_week_offset -1 3 09:00:00)"
    ts_out2="$(_view_ts_at_week_offset -1 3 11:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in1" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out1" >/dev/null 2>&1
    "$CLK_SCRIPT" in dev at "$ts_in2" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out2" >/dev/null 2>&1
    clk_test__assert_output_contains "by day" \
        "$CLK_SCRIPT" view -2 weeks through -1 week for dev by day
}

test_view_through_invalid_order() {
    # -1 week through -2 weeks should fail (end before start)
    clk_test__assert_exit 1 "$CLK_SCRIPT" view -1 week through -2 weeks
}

test_view_through_missing_offset() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view -2 weeks through
}

test_view_through_missing_unit() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" view -2 weeks through -1
}

#####################################################################
# Tests — clk view aliases (today, yesterday, this)
#####################################################################

test_view_today_alias_standalone() {
    # 'clk view today' still works (existing behavior)
    clk_test__assert_output_contains "Today" "$CLK_SCRIPT" view today
}

test_view_today_alias_offset() {
    # 'clk view today' as offset (implies day, no unit needed)
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset 0 09:00:00)"
    ts_out="$(_view_ts_at_day_offset 0 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Today" \
        "$CLK_SCRIPT" view today
}

test_view_yesterday_alias_offset() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -1 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Yesterday" \
        "$CLK_SCRIPT" view yesterday
}

test_sugar_today() {
    clk_test__assert_exit 0 "$CLK_SCRIPT" today &&
    clk_test__assert_output_contains "Today" "$CLK_SCRIPT" today
}

test_sugar_today_shows_data() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset 0 09:00:00)"
    ts_out="$(_view_ts_at_day_offset 0 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Today" "$CLK_SCRIPT" today
}

test_sugar_yesterday() {
    clk_test__assert_exit 0 "$CLK_SCRIPT" yesterday &&
    clk_test__assert_output_contains "Yesterday" "$CLK_SCRIPT" yesterday
}

test_sugar_yesterday_shows_data() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -1 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Yesterday" "$CLK_SCRIPT" yesterday
}

test_view_this_week() {
    # 'this' is alias for 'current'
    local ts_in ts_out
    ts_in="$(_view_ts_at_week_offset 0 2 09:00:00)"
    ts_out="$(_view_ts_at_week_offset 0 2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "This week" \
        "$CLK_SCRIPT" view this week
}

test_view_this_month() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_month_offset 0 5 09:00:00)"
    ts_out="$(_view_ts_at_month_offset 0 5 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "This month" \
        "$CLK_SCRIPT" view this month
}

test_view_yesterday_through_today() {
    # yesterday through today — both are aliases, no explicit units
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -1 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Yesterday through today" \
        "$CLK_SCRIPT" view yesterday through today
}

test_view_yesterday_through_today_shows_data() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -1 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "60" \
        "$CLK_SCRIPT" view yesterday through today
}

test_view_offset_through_today() {
    # -3 days through today
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -2 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "3 days ago through today" \
        "$CLK_SCRIPT" view -3 days through today
}

test_view_offset_through_yesterday() {
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -2 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -2 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "3 days ago through yesterday" \
        "$CLK_SCRIPT" view -3 days through yesterday
}

test_view_yesterday_through_this_week() {
    # Mixed: yesterday as start, this week as end
    local ts_in ts_out
    ts_in="$(_view_ts_at_day_offset -1 09:00:00)"
    ts_out="$(_view_ts_at_day_offset -1 10:00:00)"
    "$CLK_SCRIPT" in dev at "$ts_in" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out" >/dev/null 2>&1
    clk_test__assert_output_contains "Yesterday through this week" \
        "$CLK_SCRIPT" view yesterday through this week
}

test_view_today_with_for_by() {
    # today with for and by
    local ts_in1 ts_out1 ts_in2 ts_out2
    ts_in1="$(_view_ts_at_day_offset 0 09:00:00)"
    ts_out1="$(_view_ts_at_day_offset 0 09:30:00)"
    ts_in2="$(_view_ts_at_day_offset 0 10:00:00)"
    ts_out2="$(_view_ts_at_day_offset 0 10:30:00)"
    "$CLK_SCRIPT" in dev at "$ts_in1" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out1" >/dev/null 2>&1
    "$CLK_SCRIPT" in dev at "$ts_in2" >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at "$ts_out2" >/dev/null 2>&1
    clk_test__assert_output_contains "by session" \
        "$CLK_SCRIPT" view today for dev by session
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

    # clk view past year(s)
    test_view_past_years
    test_view_past_year_singular
    test_view_past_year_range_desc
    test_view_past_years_plural_range_desc

    # clk view for <tag1|tag2> (multi-tag filter)
    test_view_multi_tag_filter
    test_view_multi_tag_excludes_other
    test_view_multi_tag_correct_total
    test_view_multi_tag_shows_filter_label
    test_view_multi_tag_by_day

    # clk view by <day|week|month|session>
    test_view_by_day
    test_view_by_day_shows_minutes
    test_view_by_day_shows_bars
    test_view_by_week
    test_view_by_week_minutes
    test_view_by_without_for
    test_view_by_without_for_all_tags_header
    test_view_by_without_for_aggregates
    test_view_by_bad_group
    test_view_by_day_shows_header
    test_view_by_day_from_to
    test_view_by_day_stats_mean
    test_view_by_day_stats_median
    test_view_by_day_stats_stddev
    test_view_by_day_stats_skew
    test_view_by_day_stats_values
    test_view_by_week_stats
    test_view_by_month
    test_view_by_month_minutes
    test_view_by_month_shows_header
    test_view_by_month_without_for
    test_view_by_session
    test_view_by_session_shows_minutes
    test_view_by_session_shows_header
    test_view_by_session_without_for

    # clk view stats total
    test_view_by_day_stats_total
    test_view_by_day_stats_total_minutes
    test_view_by_day_stats_total_hours_minutes
    test_view_by_day_stats_total_under_60

    # clk view -<n> day(s)/week(s)/month(s)
    test_view_offset_0_day
    test_view_offset_0_days_plural
    test_view_offset_1_day
    test_view_offset_2_days
    test_view_offset_day_shows_data
    test_view_current_day
    test_view_offset_0_week
    test_view_offset_1_week
    test_view_offset_2_weeks
    test_view_current_week
    test_view_offset_week_shows_data
    test_view_offset_0_month
    test_view_offset_1_month
    test_view_offset_2_months
    test_view_current_month
    test_view_offset_month_shows_data
    test_view_offset_day_for_tag
    test_view_offset_week_by_day
    test_view_offset_missing_unit
    test_view_offset_bad_unit

    # clk view through (multi-period ranges)
    test_view_through_weeks
    test_view_through_weeks_range_desc
    test_view_through_days
    test_view_through_days_range_desc
    test_view_through_months
    test_view_through_months_range_desc
    test_view_through_current
    test_view_through_with_for
    test_view_through_with_by
    test_view_through_invalid_order
    test_view_through_missing_offset
    test_view_through_missing_unit

    # clk view aliases (today, yesterday, this)
    test_view_today_alias_standalone
    test_view_today_alias_offset
    test_view_yesterday_alias_offset

    # clk today / clk yesterday (syntactic sugar for clk view)
    test_sugar_today
    test_sugar_today_shows_data
    test_sugar_yesterday
    test_sugar_yesterday_shows_data
    test_view_this_week
    test_view_this_month
    test_view_yesterday_through_today
    test_view_yesterday_through_today_shows_data
    test_view_offset_through_today
    test_view_offset_through_yesterday
    test_view_yesterday_through_this_week
    test_view_today_with_for_by

    # clk view all
    test_view_all
    test_view_all_range_desc
    test_view_all_exit_0
    test_view_all_empty_log
    test_view_all_for_tag
    test_view_all_for_tag_by_day
)
