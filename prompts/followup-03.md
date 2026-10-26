# tomlq — follow-up 3 of 5: strings, control characters, numbers and date-times (the lexer's tail)

Read `prompts/judge-v3.md`, README §2.1 and §2.2 (the tagged forms and their value normalisation). Same session rules.
Work from `--spec-verbose --only` in this order: `valid/string`, `valid/control`, `valid/datetime`, `valid/local-*`,
`valid/float`, `valid/integer`, `valid/comment`, `valid/newline-*`, `valid/multibyte`; then `invalid/control`,
`invalid/string`, `invalid/datetime`, `invalid/local-*`, `invalid/float`, `invalid/integer`, `invalid/encoding`.

The rules you will meet:
- Escapes in basic strings decode to their characters (`\uXXXX`, `\UXXXXXXXX` to UTF-8; a surrogate or a value above
  U+10FFFF is invalid); a multi-line basic string trims the newline right after `"""` and, after a line-ending `\`, all
  whitespace up to the next non-whitespace; literal strings decode nothing. The tagged `value` is the decoded string.
- Control characters: U+0000–U+0008, U+000A–U+001F except what the form allows, and U+007F are invalid in strings,
  comments and bare keys; a bare CR (not followed by LF) is invalid; a NUL anywhere is invalid.
- Date-times are *normalised* in the tagged form: `1979-05-27 07:32:00Z` → `1979-05-27T07:32:00Z`; fields zero-padded as
  written by the corpus twins; a fractional second kept as given (toml-test compares them as values, so `07:32:00.999`
  and `07:32:00.9990` agree only if your comparison normalises — do it there, not in the emitter); the calendar is
  validated (`2021-02-30`, `2023-02-29`, hour 24, minute 60 invalid; leap seconds 60 are valid).
- Floats: `1e2` is `100.0`; `-inf`, `inf`, `nan` are their words; `_` only between digits; a leading `+` allowed; `.1`
  and `1.` invalid; exponents with `_`. Integers: bases, `_`, no leading zeros, the 64-bit range, `-0x1` invalid.
- Invalid UTF-8 in the input is a *document* error (the `invalid/encoding` cases): read bytes, not text, and refuse with
  a line:col; the runner counts the refusal.

**Verify (paste):** the per-directory counts before and after; the M1/M2 unit tests added for every escape, trimming
rule, control character and number form (`wolf test .` count); `./test.sh; echo $?`. Stop.
