#!/usr/bin/env bash
# nt-test-new.bash — tests for n/new (document creation)
#
# Sourced by nt-test; do not run directly.
# Defines: NT_TESTS_NEW (array of test function names)

#####################################################################
# Tests — nt n: basic creation
#####################################################################

test_new_creates_first_doc_md() {
    # First doc in empty dir defaults to .md extension
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001.md" \
        "n should create 001.md in empty directory"
}

test_new_first_doc_has_created_line() {
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/001.md" "created=" \
        "new doc should contain created= timestamp"
}

test_new_increments_index() {
    nt_test__create_file "001.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002.md" \
        "n should create 002.md when 001.md exists"
}

test_new_increments_past_gap() {
    # Highest existing is 005; next should be 006 regardless of gaps
    nt_test__create_file "001.md"
    nt_test__create_file "005.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/006.md" \
        "n should create 006.md (highest existing is 005)"
}

test_new_zero_pads_to_three_digits() {
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001.md" \
        "index should be zero-padded to 3 digits"
}

#####################################################################
# Tests — nt n: with title
#####################################################################

test_new_with_title() {
    "$NT_SCRIPT" n "my note" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-my-note.md" \
        "n with title should create 001-my-note.md"
}

test_new_title_spaces_become_hyphens() {
    "$NT_SCRIPT" n "hello world" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-hello-world.md" \
        "spaces in title should become hyphens"
}

test_new_inherits_delimiter_underscore() {
    nt_test__create_file "001__existing.md"
    "$NT_SCRIPT" n "second" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002__second.md" \
        "n should inherit __ delimiter from last doc"
}

test_new_inherits_delimiter_hyphen() {
    nt_test__create_file "001-existing.md"
    "$NT_SCRIPT" n "second" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002-second.md" \
        "n should inherit - delimiter from last doc"
}

test_new_default_delimiter_is_hyphen() {
    # No prior docs with delimiters — should default to hyphen
    "$NT_SCRIPT" n "first" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-first.md" \
        "default delimiter should be hyphen"
}

#####################################################################
# Tests — nt n: extension inheritance
#####################################################################

test_new_inherits_extension() {
    nt_test__create_file "001-note.txt"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002.txt" \
        "n should inherit .txt extension from last doc"
}

test_new_inherits_extension_with_title() {
    nt_test__create_file "001-note.org"
    "$NT_SCRIPT" n "second" >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/002-second.org" \
        "n with title should inherit .org extension from last doc"
}

#####################################################################
# Tests — nt n: template support
#####################################################################

test_new_uses_template_extension() {
    printf 'template content\n' > "$NT_TEST_DIR/nt_template.txt"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001.txt" \
        "n should use template extension .txt"
}

test_new_uses_template_content() {
    printf 'hello from template\n' > "$NT_TEST_DIR/nt_template.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/001.md" "hello from template" \
        "new doc should contain template content"
}

test_new_template_date_macro() {
    local today
    today="$(date '+%Y-%m-%d')"
    printf 'date: %%DATE\n' > "$NT_TEST_DIR/nt_template.md"
    "$NT_SCRIPT" n >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/001.md" "date: $today" \
        "template %DATE macro should be replaced with today's date"
}

test_new_template_title_macro() {
    printf 'title: %%TITLE\n' > "$NT_TEST_DIR/nt_template.md"
    "$NT_SCRIPT" n "my note" >/dev/null 2>&1
    nt_test__assert_file_contains "$NT_TEST_DIR/001-my-note.md" "title: my note" \
        "template %TITLE macro should be replaced with raw title"
}

test_new_too_many_templates_fails() {
    : > "$NT_TEST_DIR/nt_template.md"
    : > "$NT_TEST_DIR/nt_template.txt"
    nt_test__assert_exit 5 "$NT_SCRIPT" n
}

#####################################################################
# Tests — nt n: exit code
#####################################################################

test_new_exits_zero() {
    nt_test__assert_exit 0 "$NT_SCRIPT" n
}

#####################################################################
# Tests — nt n: greedy bare mode (Phase 3)
# Reserved words are consumed as part of the title in bare mode.
#####################################################################

test_new_bare_greedy_consumes_reserved_word() {
    # 'new' would have been a reserved token in the old non-greedy design;
    # in bare mode it becomes part of the title
    "$NT_SCRIPT" n my new note >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-my-new-note.md" \
        "bare n should greedily consume 'new' as part of the title"
}

test_new_bare_greedy_consumes_rename_word() {
    "$NT_SCRIPT" n title rename something >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-title-rename-something.md" \
        "bare n should greedily consume 'rename' as part of the title"
}

#####################################################################
# Tests — nt -n / --new: hyphen-prefixed non-greedy mode (Phase 3)
#####################################################################

test_new_hyphen_short_creates_doc() {
    env NT_EDITOR="true" "$NT_SCRIPT" -n my note >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-my-note.md" \
        "-n should create titled doc"
}

test_new_hyphen_long_creates_doc() {
    env NT_EDITOR="true" "$NT_SCRIPT" --new my note >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-my-note.md" \
        "--new should create titled doc"
}

test_new_hyphen_consumes_bare_number_as_title() {
    # In non-greedy mode, bare numbers do NOT stop consumption;
    # only hyphen-prefixed args do. All chained indices must use -N syntax.
    env NT_EDITOR="true" "$NT_SCRIPT" -n my note 5 >/dev/null 2>&1
    nt_test__assert_file_exists "$NT_TEST_DIR/001-my-note-5.md" \
        "-n should consume bare number as part of title"
}

test_new_hyphen_stops_at_flag() {
    # -R following --new should open the README, not be part of the title
    nt_test__create_file "README.md"
    local output
    output="$(env NT_EDITOR="echo" "$NT_SCRIPT" --new my note -R 2>&1)"
    nt_test__assert_file_exists "$NT_TEST_DIR/001-my-note.md" \
        "--new should create titled doc, stopping before -R"
    printf '%s' "$output" | grep -q "README.md" || {
        printf 'FAIL: README.md not opened after --new ...\n  output: %s\n' "$output"
        NT_TEST_FAIL=$(( NT_TEST_FAIL + 1 ))
        return 1
    }
    NT_TEST_PASS=$(( NT_TEST_PASS + 1 ))
}

#####################################################################
# Test registry
#####################################################################

NT_TESTS_NEW=(
    test_new_creates_first_doc_md
    test_new_first_doc_has_created_line
    test_new_increments_index
    test_new_increments_past_gap
    test_new_zero_pads_to_three_digits
    test_new_with_title
    test_new_title_spaces_become_hyphens
    test_new_inherits_delimiter_underscore
    test_new_inherits_delimiter_hyphen
    test_new_default_delimiter_is_hyphen
    test_new_inherits_extension
    test_new_inherits_extension_with_title
    test_new_uses_template_extension
    test_new_uses_template_content
    test_new_template_date_macro
    test_new_template_title_macro
    test_new_too_many_templates_fails
    test_new_exits_zero
    test_new_bare_greedy_consumes_reserved_word
    test_new_bare_greedy_consumes_rename_word
    test_new_hyphen_short_creates_doc
    test_new_hyphen_long_creates_doc
    test_new_hyphen_consumes_bare_number_as_title
    test_new_hyphen_stops_at_flag
)
