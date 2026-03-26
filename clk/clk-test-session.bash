#!/usr/bin/env bash
# clk-test-session.bash — integration tests for in, out, status, last, last-done, lifecycle
#
# Sourced by clk-test; do not run directly.
# Defines: CLK_TESTS_SESSION (array of test function names)

#####################################################################
# Tests — clk in (integration, via $CLK_SCRIPT)
#####################################################################

test_in_basic() {
    "$CLK_SCRIPT" in foo at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_log_line 1 '^active	2026-01-01T09:00:00		foo		0		$'
}

test_in_with_description() {
    "$CLK_SCRIPT" in foo at 2026-01-01T09:00:00 on doing stuff >/dev/null 2>&1
    clk_test__assert_log_line 1 'doing stuff$'
}

test_in_with_minus() {
    "$CLK_SCRIPT" in foo minus 30 >/dev/null 2>&1
    # Just check it created an active record for foo
    clk_test__assert_log_line 1 '^active	.*	foo	'
}

test_in_duplicate_tag() {
    "$CLK_SCRIPT" in foo at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 5 "$CLK_SCRIPT" in foo at 2026-01-01T10:00:00
}

test_in_duplicate_tag_message() {
    "$CLK_SCRIPT" in foo at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "already has an active session" "$CLK_SCRIPT" in foo at 2026-01-01T10:00:00
}

test_in_allows_different_tag() {
    "$CLK_SCRIPT" in foo at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" in bar at 2026-01-01T09:30:00
}

test_in_numeric_tag_rejected() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" in 123 at 2026-01-01T09:00:00
}

test_in_missing_tag() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" in
}

test_in_bad_timestamp() {
    clk_test__assert_exit 1 "$CLK_SCRIPT" in foo at nope
}

test_in_creates_undo() {
    "$CLK_SCRIPT" in foo at 2026-01-01T09:00:00 >/dev/null 2>&1
    if [ ! -f "${CLK_TEST_DIR}/clk/clk.tsv.undo" ]; then
        printf 'FAIL: .undo file not created by clk in\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_in_confirmation_output() {
    local output
    output="$("$CLK_SCRIPT" in foo at 2026-01-01T09:00:00 2>&1)"
    clk_test__assert_output_contains "Started session" printf '%s' "$output" &&
    clk_test__assert_output_contains "foo" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-01-01 09:00" printf '%s' "$output"
}

test_in_space_format_timestamp() {
    "$CLK_SCRIPT" in work at '2026-01-15 14:30' >/dev/null 2>&1
    clk_test__assert_log_line 1 '^active	2026-01-15T14:30:00	'
}

test_out_display_simplified_timestamps() {
    "$CLK_SCRIPT" in work at 2026-01-15T09:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" out work at 2026-01-15T10:00:00 2>&1)"
    clk_test__assert_output_contains "2026-01-15 09:00" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-01-15 10:00" printf '%s' "$output"
}

test_last_shows_full_timestamps() {
    "$CLK_SCRIPT" in work at 2026-01-15T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-15T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" last 2>&1)"
    clk_test__assert_output_contains "2026-01-15T09:00:00" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-01-15T10:00:00" printf '%s' "$output"
}


#####################################################################
# Tests — clk out (integration)
#####################################################################

test_out_basic() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Should have a done record: 1h = 3600s
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00	2026-01-01T10:00:00	work	3600	0	'
}

test_out_implicit_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 0 "$CLK_SCRIPT" out at 2026-01-01T10:00:00
}

test_out_implicit_tag_correct_record() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_log_line 1 'work	3600'
}

test_out_ambiguous_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" out at 2026-01-01T10:00:00
}

test_out_ambiguous_tag_message() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    clk_test__assert_output_contains "Multiple active sessions" "$CLK_SCRIPT" out at 2026-01-01T10:00:00
}

test_out_wrong_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 5 "$CLK_SCRIPT" out nope at 2026-01-01T10:00:00
}

test_out_no_active_sessions() {
    clk_test__assert_exit 5 "$CLK_SCRIPT" out work at 2026-01-01T10:00:00
}

test_out_description_override() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 on old desc >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 on new desc >/dev/null 2>&1
    clk_test__assert_log_line 1 'new desc$'
}

test_out_keeps_in_description() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 on original desc >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_log_line 1 'original desc$'
}

test_out_length_calculation() {
    # 2h session = 7200s
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T11:00:00 >/dev/null 2>&1
    clk_test__assert_log_line 1 '7200	0'
}

test_out_with_minus() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work minus 0 >/dev/null 2>&1
    # Should succeed (ends at now)
    clk_test__assert_log_line 1 '^done	2026-01-01T09:00:00'
}

test_out_ordering_with_remaining_active() {
    # After out, done record should be before remaining active records
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    # Line 2 should be done (work), line 3 should be active (play)
    local log_file="$CLK_TEST_DIR/clk/clk.tsv"
    local line2 line3
    line2="$(awk 'NR==2' "$log_file")"
    line3="$(awk 'NR==3' "$log_file")"
    if ! printf '%s' "$line2" | grep -q '^done'; then
        printf 'FAIL: line 2 should be done record\n  actual: %s\n' "$line2"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$line3" | grep -q '^active'; then
        printf 'FAIL: line 3 should be active record\n  actual: %s\n' "$line3"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_out_confirmation_output() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "Recorded session" "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 &&
    "$CLK_SCRIPT" in play at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "1h 0m" "$CLK_SCRIPT" out play at 2026-01-01T11:00:00
}

#####################################################################
# Tests — clk status (integration)
#####################################################################

test_status_no_active() {
    clk_test__assert_output_contains "No active sessions" "$CLK_SCRIPT" status
}

test_status_shows_tag() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "work" "$CLK_SCRIPT" status
}

test_status_shows_start_time() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "2026-01-01 09:00" "$CLK_SCRIPT" status
}

test_status_shows_active() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "active" "$CLK_SCRIPT" status
}

test_status_multiple_sessions() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-01-01T09:30:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" status 2>&1)"
    if ! printf '%s' "$output" | grep -q "work" || ! printf '%s' "$output" | grep -q "play"; then
        printf 'FAIL: status should show both active sessions\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_status_alignment() {
    # Tags of different lengths: "short" (5) and "longer-tag" (10)
    # "started" should be at the same column offset in both rows
    "$CLK_SCRIPT" in short at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in longer-tag at 2026-01-01T09:30:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" status 2>&1)"
    # Extract the column position of "started" on each line
    local col1 col2
    col1="$(printf '%s' "$output" | grep "short" | grep -bo "started" | head -1 | cut -d: -f1)"
    col2="$(printf '%s' "$output" | grep "longer-tag" | grep -bo "started" | head -1 | cut -d: -f1)"
    if [ "$col1" != "$col2" ]; then
        printf 'FAIL: "started" not aligned: col %s vs col %s\n  actual:\n%s\n' "$col1" "$col2" "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_status_not_shown_after_out() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "No active sessions" "$CLK_SCRIPT" status
}

test_status_alias_s() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "work" "$CLK_SCRIPT" s
}

#####################################################################
# Tests — clk last (integration)
#####################################################################

test_last_default() {
    # Default (no arg) shows most recent done session with -1 prefix
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" last 2>&1)"
    if ! printf '%s' "$output" | grep -q 'work'; then
        printf 'FAIL: last default should show work\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$output" | grep -q '^\-1'; then
        printf 'FAIL: last default should show -1 prefix\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_last_negative_index() {
    # -1 = most recent done, -2 = second-to-last done
    "$CLK_SCRIPT" in a at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out a at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in b at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out b at 2026-01-01T11:00:00 >/dev/null 2>&1
    local out1 out2
    out1="$("$CLK_SCRIPT" last -1 2>&1)"
    out2="$("$CLK_SCRIPT" last -2 2>&1)"
    if ! printf '%s' "$out1" | grep -q 'b' || ! printf '%s' "$out1" | grep -q '^\-1'; then
        printf 'FAIL: last -1 should show b with -1 prefix\n  actual: %s\n' "$out1"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$out2" | grep -q '  a  ' || ! printf '%s' "$out2" | grep -q '^\-2'; then
        printf 'FAIL: last -2 should show a with -2 prefix\n  actual: %s\n' "$out2"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_last_positive_index() {
    # 1 = oldest active, 2 = second-oldest active
    "$CLK_SCRIPT" in a at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in b at 2026-01-01T09:30:00 >/dev/null 2>&1
    local out1 out2
    out1="$("$CLK_SCRIPT" last 1 2>&1)"
    out2="$("$CLK_SCRIPT" last 2 2>&1)"
    if ! printf '%s' "$out1" | grep -q '  a  ' || ! printf '%s' "$out1" | grep -q '^\+1'; then
        printf 'FAIL: last 1 should show a with +1 prefix\n  actual: %s\n' "$out1"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if ! printf '%s' "$out2" | grep -q 'b' || ! printf '%s' "$out2" | grep -q '^\+2'; then
        printf 'FAIL: last 2 should show b with +2 prefix\n  actual: %s\n' "$out2"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_last_negative_excludes_active() {
    # Negative index only touches done pool; active sessions are invisible to it
    "$CLK_SCRIPT" in a at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out a at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in b at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" last -1 2>&1)"
    clk_test__assert_output_contains "a" printf '%s' "$output"
    if printf '%s' "$output" | grep -q "(active"; then
        printf 'FAIL: last -1 should not show active session\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_last_positive_shows_active() {
    # Positive index shows active sessions
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" last 1 2>&1)"
    clk_test__assert_output_contains "active" printf '%s' "$output"
}

test_last_alias_l() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_output_contains "work" "$CLK_SCRIPT" l
}

test_last_empty_log() {
    clk_test__assert_output_contains "No completed records" "$CLK_SCRIPT" last
}

test_last_no_active_sessions() {
    clk_test__assert_output_contains "No active sessions" "$CLK_SCRIPT" last 1
}

test_last_negative_out_of_range() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" last -5
}

test_last_positive_out_of_range() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    clk_test__assert_exit 1 "$CLK_SCRIPT" last 5
}

test_last_shorthand_dash_n() {
    # clk -2 = clk last -2 = second-to-last done session
    "$CLK_SCRIPT" in a at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out a at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in b at 2026-01-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out b at 2026-01-01T11:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" -2 2>&1)"
    clk_test__assert_output_contains "a" printf '%s' "$output"
    if printf '%s' "$output" | grep -q "b  "; then
        printf 'FAIL: clk -2 should show only the second-to-last done (a), not b\n  actual: %s\n' "$output"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_last_shorthand_dash_1() {
    "$CLK_SCRIPT" in work at 2026-01-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-01-01T10:00:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" -1 2>&1)"
    clk_test__assert_output_contains "work" printf '%s' "$output"
}

#####################################################################
# Tests — core lifecycle (end-to-end integration)
#####################################################################

test_lifecycle_in_out_last() {
    # Full cycle: in → out → last shows the completed record
    "$CLK_SCRIPT" in dev at 2026-03-01T08:00:00 on feature work >/dev/null 2>&1
    "$CLK_SCRIPT" out dev at 2026-03-01T10:30:00 >/dev/null 2>&1
    local output
    output="$("$CLK_SCRIPT" last 2>&1)"
    # Should show: dev, both timestamps, 2h 30m (9000s), description
    clk_test__assert_output_contains "dev" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-03-01T08:00:00" printf '%s' "$output" &&
    clk_test__assert_output_contains "2026-03-01T10:30:00" printf '%s' "$output" &&
    clk_test__assert_output_contains "2h 30m" printf '%s' "$output" &&
    clk_test__assert_output_contains "feature work" printf '%s' "$output"
}

test_lifecycle_multiple_sessions() {
    # Two sessions done: last -1 shows play (most recent), last -2 shows work
    "$CLK_SCRIPT" in work at 2026-03-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out work at 2026-03-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-03-01T10:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" out play at 2026-03-01T11:00:00 >/dev/null 2>&1
    local out1 out2
    out1="$("$CLK_SCRIPT" last -1 2>&1)"
    out2="$("$CLK_SCRIPT" last -2 2>&1)"
    clk_test__assert_output_contains "play" printf '%s' "$out1" &&
    clk_test__assert_output_contains "work" printf '%s' "$out2"
}

test_lifecycle_concurrent_sessions() {
    # Two active sessions simultaneously
    "$CLK_SCRIPT" in work at 2026-03-01T09:00:00 >/dev/null 2>&1
    "$CLK_SCRIPT" in play at 2026-03-01T09:30:00 >/dev/null 2>&1
    # Both should appear in status
    local status_out
    status_out="$("$CLK_SCRIPT" status 2>&1)"
    clk_test__assert_output_contains "work" printf '%s' "$status_out" &&
    clk_test__assert_output_contains "play" printf '%s' "$status_out" &&
    # Close one, the other should remain
    "$CLK_SCRIPT" out work at 2026-03-01T10:00:00 >/dev/null 2>&1
    status_out="$("$CLK_SCRIPT" status 2>&1)"
    clk_test__assert_output_contains "play" printf '%s' "$status_out"
}

#####################################################################
# Test list
#####################################################################

CLK_TESTS_SESSION=(
    # clk in (integration)
    test_in_basic
    test_in_with_description
    test_in_with_minus
    test_in_duplicate_tag
    test_in_duplicate_tag_message
    test_in_allows_different_tag
    test_in_numeric_tag_rejected
    test_in_missing_tag
    test_in_bad_timestamp
    test_in_creates_undo
    test_in_confirmation_output
    test_in_space_format_timestamp
    test_out_display_simplified_timestamps
    test_last_shows_full_timestamps

    # clk out (integration)
    test_out_basic
    test_out_implicit_tag
    test_out_implicit_tag_correct_record
    test_out_ambiguous_tag
    test_out_ambiguous_tag_message
    test_out_wrong_tag
    test_out_no_active_sessions
    test_out_description_override
    test_out_keeps_in_description
    test_out_length_calculation
    test_out_with_minus
    test_out_ordering_with_remaining_active
    test_out_confirmation_output

    # clk status (integration)
    test_status_no_active
    test_status_shows_tag
    test_status_shows_start_time
    test_status_shows_active
    test_status_multiple_sessions
    test_status_alignment
    test_status_not_shown_after_out
    test_status_alias_s

    # clk last (integration)
    test_last_default
    test_last_negative_index
    test_last_positive_index
    test_last_negative_excludes_active
    test_last_positive_shows_active
    test_last_alias_l
    test_last_empty_log
    test_last_no_active_sessions
    test_last_negative_out_of_range
    test_last_positive_out_of_range
    test_last_shorthand_dash_n
    test_last_shorthand_dash_1

    # core lifecycle (end-to-end)
    test_lifecycle_in_out_last
    test_lifecycle_multiple_sessions
    test_lifecycle_concurrent_sessions
)
