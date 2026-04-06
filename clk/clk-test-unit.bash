#!/usr/bin/env bash
# clk-test-unit.bash — unit tests for clk internal helpers
#
# Sourced by clk-test; do not run directly.
# Defines: CLK_TESTS_UNIT (array of test function names)

#####################################################################
# Tests — clk__die
#####################################################################

test_die_exit_code() {
    clk_test__assert_exit 1 clk__die 1 "test error" &&
    clk_test__assert_exit 4 clk__die 4 "date error"
}

test_die_message() {
    clk_test__assert_output_contains "clk: something broke" clk__die 1 "something broke"
}

test_die_upstream_detail() {
    clk_test__assert_output_contains "date: illegal" clk__die 4 "parse failed" "date: illegal time format"
}

#####################################################################
# Tests — clk__to_epoch / clk__from_epoch round-trip
#####################################################################

test_to_epoch_valid() {
    local epoch
    epoch="$(clk__to_epoch "2026-01-01T00:00:00")"
    # Just check it's a reasonable epoch (non-empty integer)
    if ! printf '%s' "$epoch" | grep -Eq '^[0-9]+$'; then
        printf 'FAIL: clk__to_epoch returned non-integer: "%s"\n' "$epoch"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_to_epoch_invalid() {
    clk_test__assert_exit 4 clk__to_epoch "not-a-date"
}

test_epoch_roundtrip() {
    local ts="2026-03-19T14:30:00"
    local epoch result
    epoch="$(clk__to_epoch "$ts")"
    result="$(clk__from_epoch "$epoch")"
    clk_test__assert_equals "$ts" "$result" "epoch round-trip for $ts"
}

test_epoch_roundtrip_midnight() {
    local ts="2026-01-01T00:00:00"
    local epoch result
    epoch="$(clk__to_epoch "$ts")"
    result="$(clk__from_epoch "$epoch")"
    clk_test__assert_equals "$ts" "$result" "epoch round-trip for midnight"
}

test_epoch_roundtrip_end_of_day() {
    local ts="2026-12-31T23:59:00"
    local epoch result
    epoch="$(clk__to_epoch "$ts")"
    result="$(clk__from_epoch "$epoch")"
    clk_test__assert_equals "$ts" "$result" "epoch round-trip for end of day"
}

#####################################################################
# Tests — clk__now_epoch / clk__now_fmt
#####################################################################

test_now_epoch_is_integer() {
    local epoch
    epoch="$(clk__now_epoch)"
    if ! printf '%s' "$epoch" | grep -Eq '^[0-9]+$'; then
        printf 'FAIL: clk__now_epoch returned non-integer: "%s"\n' "$epoch"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_now_fmt_matches_format() {
    local ts
    ts="$(clk__now_fmt)"
    if ! printf '%s' "$ts" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$'; then
        printf 'FAIL: clk__now_fmt returned invalid format: "%s"\n' "$ts"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_now_roundtrip() {
    # now_epoch and now_fmt should agree (within the same minute)
    local epoch fmt_epoch fmt_ts
    fmt_ts="$(clk__now_fmt)"
    fmt_epoch="$(clk__to_epoch "$fmt_ts")"
    epoch="$(clk__now_epoch)"
    # They should be within 60 seconds of each other
    local diff=$(( epoch - fmt_epoch ))
    if [ "$diff" -lt 0 ]; then diff=$(( -diff )); fi
    if [ "$diff" -gt 60 ]; then
        printf 'FAIL: now_epoch and now_fmt differ by %d seconds\n' "$diff"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Tests — clk__resolve_time
#####################################################################

test_resolve_time_at() {
    local result
    result="$(clk__resolve_time "2026-03-19T10:00:00" "")"
    clk_test__assert_equals "2026-03-19T10:00:00" "$result" "resolve_time with at value"
}

test_resolve_time_minus() {
    # resolve_time with minus_secs should return now - N seconds
    # Use epoch comparison with 2-second tolerance to avoid race conditions
    local result now_epoch expected_epoch result_epoch
    now_epoch="$(clk__now_epoch)"
    expected_epoch=$(( now_epoch - 1800 ))
    result="$(clk__resolve_time "" "1800")"
    result_epoch="$(clk__to_epoch "$result")"
    local diff=$(( result_epoch - expected_epoch ))
    if [ "$diff" -lt 0 ]; then diff=$(( -diff )); fi
    if [ "$diff" -gt 2 ]; then
        printf 'FAIL: resolve_time with minus 30: off by %d seconds\n' "$diff"
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_resolve_time_now() {
    # resolve_time with both empty should return now
    local result now_ts
    now_ts="$(clk__now_fmt)"
    result="$(clk__resolve_time "" "")"
    clk_test__assert_equals "$now_ts" "$result" "resolve_time with neither at nor minus"
}

test_resolve_time_at_takes_precedence() {
    # If both at and minus are set, at wins
    local result
    result="$(clk__resolve_time "2026-03-19T10:00:00" "30")"
    clk_test__assert_equals "2026-03-19T10:00:00" "$result" "resolve_time: at takes precedence over minus"
}

#####################################################################
# Tests — clk__fmt_duration
#####################################################################

test_fmt_duration_zero() {
    local result
    result="$(clk__fmt_duration 0)"
    clk_test__assert_equals "0m" "$result" "fmt_duration(0)"
}

test_fmt_duration_sub_minute() {
    local result
    result="$(clk__fmt_duration 45)"
    clk_test__assert_equals "0m" "$result" "fmt_duration(45) rounds down"
}

test_fmt_duration_exact_minutes() {
    local result
    result="$(clk__fmt_duration 300)"
    clk_test__assert_equals "5m" "$result" "fmt_duration(300) = 5m"
}

test_fmt_duration_hours_and_minutes() {
    local result
    result="$(clk__fmt_duration 3660)"
    clk_test__assert_equals "1h 1m" "$result" "fmt_duration(3660) = 1h 1m"
}

test_fmt_duration_exact_hours() {
    local result
    result="$(clk__fmt_duration 7200)"
    clk_test__assert_equals "2h 0m" "$result" "fmt_duration(7200) = 2h 0m"
}

test_fmt_duration_large() {
    local result
    result="$(clk__fmt_duration 36000)"
    clk_test__assert_equals "10h 0m" "$result" "fmt_duration(36000) = 10h 0m"
}

#####################################################################
# Tests — clk__read_line
#####################################################################

test_read_line_done_record() {
    local tab=$'\t'
    local line="done${tab}2026-03-19T09:00:00${tab}2026-03-19T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}wrote code"
    clk__read_line "$line"
    clk_test__assert_equals "done" "$CLK_F1" "read_line F1=status" &&
    clk_test__assert_equals "2026-03-19T09:00:00" "$CLK_F2" "read_line F2=start" &&
    clk_test__assert_equals "2026-03-19T10:00:00" "$CLK_F3" "read_line F3=end" &&
    clk_test__assert_equals "work" "$CLK_F4" "read_line F4=tag" &&
    clk_test__assert_equals "3600" "$CLK_F5" "read_line F5=length" &&
    clk_test__assert_equals "0" "$CLK_F6" "read_line F6=break" &&
    clk_test__assert_equals "" "$CLK_F7" "read_line F7=paused_at (empty)" &&
    clk_test__assert_equals "wrote code" "$CLK_F8" "read_line F8=description"
}

test_read_line_active_record() {
    local tab=$'\t'
    local line="active${tab}2026-03-19T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk__read_line "$line"
    clk_test__assert_equals "active" "$CLK_F1" "read_line active F1=status" &&
    clk_test__assert_equals "2026-03-19T09:00:00" "$CLK_F2" "read_line active F2=start" &&
    clk_test__assert_equals "" "$CLK_F3" "read_line active F3=end (empty)" &&
    clk_test__assert_equals "work" "$CLK_F4" "read_line active F4=tag" &&
    clk_test__assert_equals "" "$CLK_F5" "read_line active F5=length (empty)" &&
    clk_test__assert_equals "0" "$CLK_F6" "read_line active F6=break"
}

#####################################################################
# Tests — clk__fmt_record
#####################################################################

test_fmt_record_done_basic() {
    local tab=$'\t'
    local line="done${tab}2026-03-19T09:00:00${tab}2026-03-19T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    local result
    result="$(clk__fmt_record "$line")"
    # Start and end share the date, so the end-date is elided:
    #   "2026-03-19 09:00 → 10:00" rather than
    #   "2026-03-19 09:00 → 2026-03-19 10:00"
    clk_test__assert_output_contains "work" printf '%s' "$result" &&
    clk_test__assert_output_contains "2026-03-19 09:00 → 10:00" printf '%s' "$result" &&
    clk_test__assert_output_contains "1h 0m" printf '%s' "$result"
}

test_fmt_record_done_with_break() {
    local tab=$'\t'
    local line="done${tab}2026-03-19T09:00:00${tab}2026-03-19T10:30:00${tab}work${tab}4800${tab}600${tab}${tab}"
    local result
    result="$(clk__fmt_record "$line")"
    clk_test__assert_output_contains "(break: 10m)" printf '%s' "$result"
}

test_fmt_record_done_with_description() {
    local tab=$'\t'
    local line="done${tab}2026-03-19T09:00:00${tab}2026-03-19T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}wrote tests"
    local result
    result="$(clk__fmt_record "$line")"
    clk_test__assert_output_contains "wrote tests" printf '%s' "$result"
}

test_fmt_record_active_basic() {
    local tab=$'\t'
    local line="active${tab}2026-03-19T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    local result
    result="$(clk__fmt_record "$line")"
    clk_test__assert_output_contains "work" printf '%s' "$result" &&
    clk_test__assert_output_contains "started at 2026-03-19 09:00" printf '%s' "$result" &&
    clk_test__assert_output_contains "(active" printf '%s' "$result"
}

#####################################################################
# Tests — clk__validate_tag
#####################################################################

test_validate_tag_valid() {
    # Should not exit / error
    clk_test__assert_exit 0 clk__validate_tag "work"
}

test_validate_tag_valid_dotted() {
    clk_test__assert_exit 0 clk__validate_tag "pm.bills"
}

test_validate_tag_empty() {
    clk_test__assert_exit 1 clk__validate_tag ""
}

test_validate_tag_numeric() {
    clk_test__assert_exit 1 clk__validate_tag "123"
}

test_validate_tag_numeric_message() {
    clk_test__assert_output_contains "purely numeric" clk__validate_tag "42"
}

test_validate_tag_with_space() {
    clk_test__assert_exit 1 clk__validate_tag "my tag"
}

test_validate_tag_with_tab() {
    local tab=$'\t'
    clk_test__assert_exit 1 clk__validate_tag "my${tab}tag"
}

#####################################################################
# Tests — clk__validate_timestamp
#####################################################################

test_validate_timestamp_valid() {
    clk_test__assert_exit 0 clk__validate_timestamp "2026-03-19T14:30:00"
}

test_validate_timestamp_invalid_format() {
    clk_test__assert_exit 1 clk__validate_timestamp "2026/03/19 14:30"
}

test_validate_timestamp_invalid_text() {
    clk_test__assert_exit 1 clk__validate_timestamp "nope"
}

test_validate_timestamp_missing_part() {
    clk_test__assert_exit 1 clk__validate_timestamp "2026.03.19"
}

test_validate_timestamp_error_message() {
    clk_test__assert_output_contains "Invalid timestamp" clk__validate_timestamp "bad"
}

#####################################################################
# Tests — clk__normalize_timestamp
#####################################################################

test_normalize_timestamp_full_format() {
    local result
    result="$(clk__normalize_timestamp "2026-03-20T11:53:00")"
    clk_test__assert_equals "2026-03-20T11:53:00" "$result" "normalize full format unchanged"
}

test_normalize_timestamp_no_seconds() {
    local result
    result="$(clk__normalize_timestamp "2026-03-20T11:53")"
    clk_test__assert_equals "2026-03-20T11:53:00" "$result" "normalize yyyy-mm-ddTHH:MM appends :00"
}

test_normalize_timestamp_time_with_seconds() {
    local result today
    today="$(date +%Y-%m-%d)"
    result="$(clk__normalize_timestamp "15:39:00")"
    clk_test__assert_equals "${today}T15:39:00" "$result" "normalize HH:MM:SS prepends today"
}

test_normalize_timestamp_time_only() {
    local result today
    today="$(date +%Y-%m-%d)"
    result="$(clk__normalize_timestamp "15:39")"
    clk_test__assert_equals "${today}T15:39:00" "$result" "normalize HH:MM prepends today and appends :00"
}

test_normalize_timestamp_passthrough_invalid() {
    # Invalid input passes through unchanged (validate catches it later)
    local result
    result="$(clk__normalize_timestamp "nope")"
    clk_test__assert_equals "nope" "$result" "normalize passes through invalid input"
}

test_normalize_timestamp_space_format() {
    local result
    result="$(clk__normalize_timestamp "2026-03-19 12:16")"
    clk_test__assert_equals "2026-03-19T12:16:00" "$result" "normalize yyyy-mm-dd HH:MM to full format"
}

test_normalize_timestamp_date_only() {
    local result
    result="$(clk__normalize_timestamp "2026-03-19")"
    clk_test__assert_equals "2026-03-19T00:00:00" "$result" "normalize yyyy-mm-dd to midnight"
}

test_normalize_timestamp_mmdd() {
    local result year
    year="$(date +%Y)"
    result="$(clk__normalize_timestamp "03-15")"
    clk_test__assert_equals "${year}-03-15T00:00:00" "$result" "normalize mm-dd to this year midnight"
}

test_normalize_timestamp_mmdd_time() {
    local result year
    year="$(date +%Y)"
    result="$(clk__normalize_timestamp "03-15 14:30")"
    clk_test__assert_equals "${year}-03-15T14:30:00" "$result" "normalize mm-dd HH:MM to this year"
}

#####################################################################
# Tests — clk__validate_timestamp with simplified formats
#####################################################################

test_validate_timestamp_no_seconds() {
    clk_test__assert_exit 0 clk__validate_timestamp "2026-03-20T11:53"
}

test_validate_timestamp_time_only() {
    clk_test__assert_exit 0 clk__validate_timestamp "00:01"
}

test_validate_timestamp_time_with_seconds() {
    clk_test__assert_exit 0 clk__validate_timestamp "00:01:00"
}

test_validate_timestamp_sets_validated_ts() {
    clk__validate_timestamp "2026-03-20T11:53"
    clk_test__assert_equals "2026-03-20T11:53:00" "$CLK_VALIDATED_TS" "CLK_VALIDATED_TS normalized"
}

test_validate_timestamp_time_only_sets_validated_ts() {
    local today
    today="$(date +%Y-%m-%d)"
    clk__validate_timestamp "00:01"
    clk_test__assert_equals "${today}T00:01:00" "$CLK_VALIDATED_TS" "CLK_VALIDATED_TS from HH:MM"
}

test_validate_timestamp_space_format() {
    clk_test__assert_exit 0 clk__validate_timestamp "2026-03-19 12:16"
}

test_validate_timestamp_space_format_sets_validated_ts() {
    clk__validate_timestamp "2026-03-19 12:16"
    clk_test__assert_equals "2026-03-19T12:16:00" "$CLK_VALIDATED_TS" "CLK_VALIDATED_TS from space format"
}

test_validate_timestamp_date_only() {
    clk_test__assert_exit 0 clk__validate_timestamp "2026-03-19"
}

test_validate_timestamp_date_only_sets_validated_ts() {
    clk__validate_timestamp "2026-03-19"
    clk_test__assert_equals "2026-03-19T00:00:00" "$CLK_VALIDATED_TS" "CLK_VALIDATED_TS from date-only"
}

test_validate_timestamp_mmdd() {
    clk_test__assert_exit 0 clk__validate_timestamp "01-01"
}

test_validate_timestamp_mmdd_sets_validated_ts() {
    local year
    year="$(date +%Y)"
    clk__validate_timestamp "01-01"
    clk_test__assert_equals "${year}-01-01T00:00:00" "$CLK_VALIDATED_TS" "CLK_VALIDATED_TS from mm-dd"
}

test_validate_timestamp_mmdd_time() {
    clk_test__assert_exit 0 clk__validate_timestamp "01-01 10:00"
}

test_validate_timestamp_mmdd_time_sets_validated_ts() {
    local year
    year="$(date +%Y)"
    clk__validate_timestamp "01-01 10:00"
    clk_test__assert_equals "${year}-01-01T10:00:00" "$CLK_VALIDATED_TS" "CLK_VALIDATED_TS from mm-dd HH:MM"
}

test_validate_timestamp_future_rejected() {
    clk_test__assert_exit 1 clk__validate_timestamp "2099-01-01T00:00:00"
}

test_validate_timestamp_future_error_message() {
    clk_test__assert_output_contains "is in the future" clk__validate_timestamp "2099-01-01T00:00:00"
}

test_validate_timestamp_future_mmdd_rejected() {
    clk_test__assert_exit 1 clk__validate_timestamp "12-31"
}

#####################################################################
# Tests — clk__fmt_ts_display
#####################################################################

test_fmt_ts_display_non_today() {
    local result
    result="$(clk__fmt_ts_display "2026-01-15T14:30:07")"
    clk_test__assert_equals "2026-01-15 14:30" "$result" "non-today: drops seconds and T"
}

test_fmt_ts_display_today() {
    local today
    today="$(date +%Y-%m-%d)"
    local result
    result="$(clk__fmt_ts_display "${today}T09:45:00")"
    clk_test__assert_equals "09:45" "$result" "today: shows only HH:MM"
}

test_fmt_ts_display_raw_mode() {
    CLK_FMT_RAW=1
    local result
    result="$(clk__fmt_ts_display "2026-01-15T14:30:07")"
    CLK_FMT_RAW=0
    clk_test__assert_equals "2026-01-15T14:30:07" "$result" "raw mode: unchanged"
}

#####################################################################
# Tests — clk__validate_positive_int
#####################################################################

test_validate_positive_int_valid() {
    clk_test__assert_exit 0 clk__validate_positive_int "42" "minutes"
}

test_validate_positive_int_zero() {
    clk_test__assert_exit 0 clk__validate_positive_int "0" "minutes"
}

test_validate_positive_int_negative() {
    clk_test__assert_exit 1 clk__validate_positive_int "-5" "minutes"
}

test_validate_positive_int_text() {
    clk_test__assert_exit 1 clk__validate_positive_int "abc" "minutes"
}

test_validate_positive_int_float() {
    clk_test__assert_exit 1 clk__validate_positive_int "3.5" "minutes"
}

test_validate_positive_int_error_message() {
    clk_test__assert_output_contains "positive integer" clk__validate_positive_int "abc" "minutes"
}

#####################################################################
# Tests — clk__save_undo
#####################################################################

test_save_undo_creates_file() {
    clk__save_undo
    if [ ! -f "${CLK_LOG}.undo" ]; then
        printf 'FAIL: .undo file not created\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_save_undo_matches_log() {
    # Add a line to the log first
    local tab=$'\t'
    clk__append_line "done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    clk__save_undo
    local log_content undo_content
    log_content="$(cat "$CLK_LOG")"
    undo_content="$(cat "${CLK_LOG}.undo")"
    clk_test__assert_equals "$log_content" "$undo_content" "undo snapshot matches log"
}

test_save_undo_clears_redo() {
    # Create a fake .redo file, then save_undo should remove it
    printf 'fake redo\n' > "${CLK_LOG}.redo"
    clk__save_undo
    if [ -f "${CLK_LOG}.redo" ]; then
        printf 'FAIL: .redo file not removed after save_undo\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

#####################################################################
# Tests — clk__append_line
#####################################################################

test_append_line_basic() {
    local tab=$'\t'
    local record="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$record"
    local last_line
    last_line="$(tail -1 "$CLK_LOG")"
    clk_test__assert_equals "$record" "$last_line" "append_line adds to end"
}

test_append_line_preserves_existing() {
    local tab=$'\t'
    local record1="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    local record2="done${tab}2026-01-01T10:00:00${tab}2026-01-01T11:00:00${tab}play${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$record1"
    clk__append_line "$record2"
    # First line should still be version marker
    local first_line
    first_line="$(head -1 "$CLK_LOG")"
    clk_test__assert_equals "#clk-v3" "$first_line" "append preserves header" &&
    # Should have 3 lines total
    local count
    count="$(wc -l < "$CLK_LOG" | tr -d ' ')"
    clk_test__assert_equals "3" "$count" "append creates correct line count"
}

#####################################################################
# Tests — clk__replace_line
#####################################################################

test_replace_line_basic() {
    local tab=$'\t'
    local original="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    local replacement="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}play${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$original"
    clk__replace_line 2 "$replacement"
    local line
    line="$(clk__get_line 2)"
    clk_test__assert_equals "$replacement" "$line" "replace_line swaps content"
}

test_replace_line_preserves_other_lines() {
    local tab=$'\t'
    local line1="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}a${tab}3600${tab}0${tab}${tab}"
    local line2="done${tab}2026-01-01T10:00:00${tab}2026-01-01T11:00:00${tab}b${tab}3600${tab}0${tab}${tab}"
    local line3="done${tab}2026-01-01T11:00:00${tab}2026-01-01T12:00:00${tab}c${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$line1"
    clk__append_line "$line2"
    clk__append_line "$line3"
    local replacement="done${tab}2026-01-01T10:00:00${tab}2026-01-01T11:00:00${tab}REPLACED${tab}3600${tab}0${tab}${tab}"
    clk__replace_line 3 "$replacement"
    # Line 2 (first data line) should be unchanged
    local got
    got="$(clk__get_line 2)"
    clk_test__assert_equals "$line1" "$got" "replace_line preserves other lines" &&
    # Line 4 should be unchanged
    got="$(clk__get_line 4)"
    clk_test__assert_equals "$line3" "$got" "replace_line preserves lines after"
}

#####################################################################
# Tests — clk__delete_line
#####################################################################

test_delete_line_basic() {
    local tab=$'\t'
    local line1="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}a${tab}3600${tab}0${tab}${tab}"
    local line2="done${tab}2026-01-01T10:00:00${tab}2026-01-01T11:00:00${tab}b${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$line1"
    clk__append_line "$line2"
    # Delete line 2 (first data line)
    clk__delete_line 2
    local count
    count="$(wc -l < "$CLK_LOG" | tr -d ' ')"
    clk_test__assert_equals "2" "$count" "delete_line reduces line count" &&
    # Remaining data line should be line2 (now at position 2)
    local got
    got="$(clk__get_line 2)"
    clk_test__assert_equals "$line2" "$got" "delete_line shifts subsequent lines up"
}

test_delete_line_last() {
    local tab=$'\t'
    local line1="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}a${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$line1"
    clk__delete_line 2
    local count
    count="$(wc -l < "$CLK_LOG" | tr -d ' ')"
    clk_test__assert_equals "1" "$count" "delete_line on last data line leaves only header"
}

#####################################################################
# Tests — clk__find_active
#####################################################################

test_find_active_none() {
    # Fresh log has no active records
    local result=0
    clk__find_active || result=$?
    clk_test__assert_equals "1" "$result" "find_active returns 1 when none found"
}

test_find_active_one() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    local lineno
    lineno="$(clk__find_active)"
    clk_test__assert_equals "2" "$lineno" "find_active returns correct line number"
}

test_find_active_multiple() {
    local tab=$'\t'
    clk__append_line "done${tab}2026-01-01T08:00:00${tab}2026-01-01T09:00:00${tab}old${tab}3600${tab}0${tab}${tab}"
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk__append_line "active${tab}2026-01-01T09:30:00${tab}${tab}play${tab}${tab}0${tab}${tab}"
    local lines
    lines="$(clk__find_active)"
    local count
    count="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
    clk_test__assert_equals "2" "$count" "find_active returns multiple lines"
}

test_find_active_by_tag() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk__append_line "active${tab}2026-01-01T09:30:00${tab}${tab}play${tab}${tab}0${tab}${tab}"
    local lineno
    lineno="$(clk__find_active "play")"
    clk_test__assert_equals "3" "$lineno" "find_active by tag returns correct line"
}

test_find_active_by_tag_not_found() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    local result=0
    clk__find_active "nope" || result=$?
    clk_test__assert_equals "1" "$result" "find_active returns 1 for missing tag"
}

test_find_active_skips_done() {
    local tab=$'\t'
    clk__append_line "done${tab}2026-01-01T08:00:00${tab}2026-01-01T09:00:00${tab}old${tab}3600${tab}0${tab}${tab}"
    local result=0
    clk__find_active || result=$?
    clk_test__assert_equals "1" "$result" "find_active ignores done records"
}

#####################################################################
# Tests — clk__insert_before_active
#####################################################################

test_insert_before_active_no_active() {
    local tab=$'\t'
    local done_rec="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    clk__insert_before_active "$done_rec"
    local last_line
    last_line="$(tail -1 "$CLK_LOG")"
    clk_test__assert_equals "$done_rec" "$last_line" "insert_before_active appends when no active"
}

test_insert_before_active_with_active() {
    local tab=$'\t'
    local active_rec="active${tab}2026-01-01T10:00:00${tab}${tab}play${tab}${tab}0${tab}${tab}"
    local done_rec="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$active_rec"
    clk__insert_before_active "$done_rec"
    # done record should be at line 2, active at line 3
    local line2 line3
    line2="$(clk__get_line 2)"
    line3="$(clk__get_line 3)"
    clk_test__assert_equals "$done_rec" "$line2" "insert_before_active: done line is before active" &&
    clk_test__assert_equals "$active_rec" "$line3" "insert_before_active: active line stays at end"
}

test_insert_before_active_multiple_active() {
    local tab=$'\t'
    local active1="active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    local active2="active${tab}2026-01-01T09:30:00${tab}${tab}play${tab}${tab}0${tab}${tab}"
    local done_rec="done${tab}2026-01-01T08:00:00${tab}2026-01-01T09:00:00${tab}old${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$active1"
    clk__append_line "$active2"
    clk__insert_before_active "$done_rec"
    # done record at line 2, active1 at line 3, active2 at line 4
    local line2 line3 line4
    line2="$(clk__get_line 2)"
    line3="$(clk__get_line 3)"
    line4="$(clk__get_line 4)"
    clk_test__assert_equals "$done_rec" "$line2" "insert_before_active: done before both active" &&
    clk_test__assert_equals "$active1" "$line3" "insert_before_active: first active preserved" &&
    clk_test__assert_equals "$active2" "$line4" "insert_before_active: second active preserved"
}

test_insert_before_active_done_then_active() {
    local tab=$'\t'
    local existing_done="done${tab}2026-01-01T07:00:00${tab}2026-01-01T08:00:00${tab}early${tab}3600${tab}0${tab}${tab}"
    local active_rec="active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    local new_done="done${tab}2026-01-01T08:00:00${tab}2026-01-01T09:00:00${tab}mid${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$existing_done"
    clk__append_line "$active_rec"
    clk__insert_before_active "$new_done"
    # Order: header, existing_done, new_done, active_rec
    local line2 line3 line4
    line2="$(clk__get_line 2)"
    line3="$(clk__get_line 3)"
    line4="$(clk__get_line 4)"
    clk_test__assert_equals "$existing_done" "$line2" "insert: existing done stays" &&
    clk_test__assert_equals "$new_done" "$line3" "insert: new done before active" &&
    clk_test__assert_equals "$active_rec" "$line4" "insert: active at end"
}

#####################################################################
# Tests — clk__require_active_tag
#####################################################################

test_require_active_tag_explicit() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk__require_active_tag "work"
    clk_test__assert_equals "work" "$CLK_ACTIVE_TAG" "require_active_tag: explicit tag" &&
    clk_test__assert_equals "2" "$CLK_ACTIVE_LINE" "require_active_tag: explicit line"
}

test_require_active_tag_implicit_single() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk__require_active_tag ""
    clk_test__assert_equals "work" "$CLK_ACTIVE_TAG" "require_active_tag: inferred tag" &&
    clk_test__assert_equals "2" "$CLK_ACTIVE_LINE" "require_active_tag: inferred line"
}

test_require_active_tag_no_active() {
    clk_test__assert_exit 5 clk__require_active_tag ""
}

test_require_active_tag_no_active_message() {
    clk_test__assert_output_contains "No active sessions" clk__require_active_tag ""
}

test_require_active_tag_ambiguous() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk__append_line "active${tab}2026-01-01T09:30:00${tab}${tab}play${tab}${tab}0${tab}${tab}"
    clk_test__assert_exit 1 clk__require_active_tag ""
}

test_require_active_tag_ambiguous_lists_tags() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk__append_line "active${tab}2026-01-01T09:30:00${tab}${tab}play${tab}${tab}0${tab}${tab}"
    clk_test__assert_output_contains "work" clk__require_active_tag "" &&
    clk_test__assert_output_contains "play" clk__require_active_tag ""
}

test_require_active_tag_wrong_tag() {
    local tab=$'\t'
    clk__append_line "active${tab}2026-01-01T09:00:00${tab}${tab}work${tab}${tab}0${tab}${tab}"
    clk_test__assert_exit 5 clk__require_active_tag "nope"
}

#####################################################################
# Tests — clk__get_line / clk__record_count
#####################################################################

test_get_line_basic() {
    local tab=$'\t'
    local record="done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}work${tab}3600${tab}0${tab}${tab}"
    clk__append_line "$record"
    local got
    got="$(clk__get_line 2)"
    clk_test__assert_equals "$record" "$got" "get_line returns correct line"
}

test_get_line_header() {
    local got
    got="$(clk__get_line 1)"
    clk_test__assert_equals "#clk-v3" "$got" "get_line 1 returns header"
}

test_record_count_empty() {
    local count
    count="$(clk__record_count)"
    clk_test__assert_equals "0" "$count" "record_count on fresh log is 0"
}

test_record_count_with_records() {
    local tab=$'\t'
    clk__append_line "done${tab}2026-01-01T09:00:00${tab}2026-01-01T10:00:00${tab}a${tab}3600${tab}0${tab}${tab}"
    clk__append_line "done${tab}2026-01-01T10:00:00${tab}2026-01-01T11:00:00${tab}b${tab}3600${tab}0${tab}${tab}"
    clk__append_line "active${tab}2026-01-01T11:00:00${tab}${tab}c${tab}${tab}0${tab}${tab}"
    local count
    count="$(clk__record_count)"
    clk_test__assert_equals "3" "$count" "record_count counts data lines"
}

#####################################################################
# Tests — clk__ensure_log
#####################################################################

test_ensure_log_creates_dir_and_file() {
    # setup already called ensure_log; check the results
    if [ ! -d "$CLK_TEST_DIR/clk" ]; then
        printf 'FAIL: clk dir not created\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    if [ ! -f "$CLK_TEST_DIR/clk/clk.tsv" ]; then
        printf 'FAIL: clk.tsv not created\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_ensure_log_has_version_marker() {
    local first_line
    first_line="$(head -1 "$CLK_LOG")"
    clk_test__assert_equals "#clk-v3" "$first_line" "log starts with version marker"
}

test_ensure_log_strips_trailing_blanks() {
    # Add some blank lines to the log and re-run ensure_log
    printf '\n\n\n' >> "$CLK_LOG"
    clk__ensure_log
    local last_line
    last_line="$(tail -1 "$CLK_LOG")"
    if [ -z "$last_line" ] || printf '%s' "$last_line" | grep -Eq '^[[:space:]]*$'; then
        printf 'FAIL: trailing blank lines not stripped\n'
        CLK_TEST_FAIL=$(( CLK_TEST_FAIL + 1 ))
        return 1
    fi
    CLK_TEST_PASS=$(( CLK_TEST_PASS + 1 ))
}

test_ensure_log_idempotent() {
    # Running ensure_log twice should not change the file
    local before after
    before="$(cat "$CLK_LOG")"
    clk__ensure_log
    after="$(cat "$CLK_LOG")"
    clk_test__assert_equals "$before" "$after" "ensure_log is idempotent"
}

#####################################################################
# Tests — clk__parse_duration
#####################################################################

test_parse_duration_plain_minutes() {
    clk__parse_duration "90"
    clk_test__assert_equals "5400" "$CLK_PARSED_DURATION_SECS" "90 minutes = 5400 seconds"
}

test_parse_duration_hours_only() {
    clk__parse_duration "2h"
    clk_test__assert_equals "7200" "$CLK_PARSED_DURATION_SECS" "2h = 7200 seconds"
}

test_parse_duration_minutes_only() {
    clk__parse_duration "45m"
    clk_test__assert_equals "2700" "$CLK_PARSED_DURATION_SECS" "45m = 2700 seconds"
}

test_parse_duration_hours_and_minutes() {
    clk__parse_duration "1h30m"
    clk_test__assert_equals "5400" "$CLK_PARSED_DURATION_SECS" "1h30m = 5400 seconds"
}

test_parse_duration_uppercase() {
    clk__parse_duration "2H15M"
    clk_test__assert_equals "8100" "$CLK_PARSED_DURATION_SECS" "2H15M = 8100 seconds"
}

test_parse_duration_zero() {
    clk__parse_duration "0"
    clk_test__assert_equals "0" "$CLK_PARSED_DURATION_SECS" "0 minutes = 0 seconds"
}

test_parse_duration_invalid() {
    clk_test__assert_exit 1 clk__parse_duration "abc"
}

test_parse_duration_invalid_mixed() {
    clk_test__assert_exit 1 clk__parse_duration "1h30"
}

#####################################################################
# Test list
#####################################################################

CLK_TESTS_UNIT=(
    # die
    test_die_exit_code
    test_die_message
    test_die_upstream_detail

    # to_epoch / from_epoch
    test_to_epoch_valid
    test_to_epoch_invalid
    test_epoch_roundtrip
    test_epoch_roundtrip_midnight
    test_epoch_roundtrip_end_of_day

    # now_epoch / now_fmt
    test_now_epoch_is_integer
    test_now_fmt_matches_format
    test_now_roundtrip

    # resolve_time
    test_resolve_time_at
    test_resolve_time_minus
    test_resolve_time_now
    test_resolve_time_at_takes_precedence

    # fmt_duration
    test_fmt_duration_zero
    test_fmt_duration_sub_minute
    test_fmt_duration_exact_minutes
    test_fmt_duration_hours_and_minutes
    test_fmt_duration_exact_hours
    test_fmt_duration_large

    # read_line
    test_read_line_done_record
    test_read_line_active_record

    # fmt_record
    test_fmt_record_done_basic
    test_fmt_record_done_with_break
    test_fmt_record_done_with_description
    test_fmt_record_active_basic

    # validate_tag
    test_validate_tag_valid
    test_validate_tag_valid_dotted
    test_validate_tag_empty
    test_validate_tag_numeric
    test_validate_tag_numeric_message
    test_validate_tag_with_space
    test_validate_tag_with_tab

    # validate_timestamp
    test_validate_timestamp_valid
    test_validate_timestamp_invalid_format
    test_validate_timestamp_invalid_text
    test_validate_timestamp_missing_part
    test_validate_timestamp_error_message

    # normalize_timestamp
    test_normalize_timestamp_full_format
    test_normalize_timestamp_no_seconds
    test_normalize_timestamp_time_with_seconds
    test_normalize_timestamp_time_only
    test_normalize_timestamp_passthrough_invalid
    test_normalize_timestamp_space_format
    test_normalize_timestamp_date_only
    test_normalize_timestamp_mmdd
    test_normalize_timestamp_mmdd_time

    # validate_timestamp with simplified formats
    test_validate_timestamp_no_seconds
    test_validate_timestamp_time_only
    test_validate_timestamp_time_with_seconds
    test_validate_timestamp_sets_validated_ts
    test_validate_timestamp_time_only_sets_validated_ts
    test_validate_timestamp_space_format
    test_validate_timestamp_space_format_sets_validated_ts
    test_validate_timestamp_date_only
    test_validate_timestamp_date_only_sets_validated_ts
    test_validate_timestamp_mmdd
    test_validate_timestamp_mmdd_sets_validated_ts
    test_validate_timestamp_mmdd_time
    test_validate_timestamp_mmdd_time_sets_validated_ts
    test_validate_timestamp_future_rejected
    test_validate_timestamp_future_error_message
    test_validate_timestamp_future_mmdd_rejected

    # fmt_ts_display
    test_fmt_ts_display_non_today
    test_fmt_ts_display_today
    test_fmt_ts_display_raw_mode

    # parse_duration
    test_parse_duration_plain_minutes
    test_parse_duration_hours_only
    test_parse_duration_minutes_only
    test_parse_duration_hours_and_minutes
    test_parse_duration_uppercase
    test_parse_duration_zero
    test_parse_duration_invalid
    test_parse_duration_invalid_mixed

    # validate_positive_int
    test_validate_positive_int_valid
    test_validate_positive_int_zero
    test_validate_positive_int_negative
    test_validate_positive_int_text
    test_validate_positive_int_float
    test_validate_positive_int_error_message

    # save_undo
    test_save_undo_creates_file
    test_save_undo_matches_log
    test_save_undo_clears_redo

    # append_line
    test_append_line_basic
    test_append_line_preserves_existing

    # replace_line
    test_replace_line_basic
    test_replace_line_preserves_other_lines

    # delete_line
    test_delete_line_basic
    test_delete_line_last

    # find_active
    test_find_active_none
    test_find_active_one
    test_find_active_multiple
    test_find_active_by_tag
    test_find_active_by_tag_not_found
    test_find_active_skips_done

    # insert_before_active
    test_insert_before_active_no_active
    test_insert_before_active_with_active
    test_insert_before_active_multiple_active
    test_insert_before_active_done_then_active

    # require_active_tag
    test_require_active_tag_explicit
    test_require_active_tag_implicit_single
    test_require_active_tag_no_active
    test_require_active_tag_no_active_message
    test_require_active_tag_ambiguous
    test_require_active_tag_ambiguous_lists_tags
    test_require_active_tag_wrong_tag

    # get_line / record_count
    test_get_line_basic
    test_get_line_header
    test_record_count_empty
    test_record_count_with_records

    # ensure_log
    test_ensure_log_creates_dir_and_file
    test_ensure_log_has_version_marker
    test_ensure_log_strips_trailing_blanks
    test_ensure_log_idempotent
)
