# tomlq — closeout 8 of 12: date-times — the four kinds and the calendar

Read `prompts/judge-v3-r2.md` (finding 8), README §2.1 and FR-10, and `prompts/close-rules.md`.

**The bugs:** a date-time without an offset is typed `datetime` (want `datetime-local`); `0001-01-01` prints as
`1-01-01` (the zero-padding helper is applied to the year); and nine invalid date-times are accepted.

## 1. Tests first (red), one per edit
Kinds: `1979-05-27T07:32:00Z` and `…-07:00` → `datetime`; `1979-05-27T07:32:00` → `datetime-local`; `1979-05-27` →
`date-local`; `07:32:00` → `time-local`. Text: a space or `t` separator prints as `T`; `z` prints as `Z`; `0001-01-01`
stays `0001-01-01`; a fraction stays as written (`.999`). Refused: `2023-02-29` (not a leap year), `2021-04-31`,
`2000-13-01`, `2000-00-10`, `1979-05-27T24:00:00`, `T07:60:00`, `T07:32:61`, `1979-05-27T07:32` and `07:32` (seconds are
required in TOML 1.0), `07:32:00.` and `…00.Z` (a dot needs digits), offsets `+24:00` and `+05:60`. Accepted:
`2024-02-29`, `2000-02-29`, `1900-02-28`, a leap second `23:59:60`. Paste `wolf test .` failing.

## 2. The fix
Keep the text-preserving design (README §2.1: validate the shape, keep the text); add the kind decision by whether an
offset is present, the calendar check (Gregorian leap years: divisible by 4, except by 100 unless by 400), the range
checks above, and the normalisation of the separator and `z`. Pad only the fields the corpus twins pad; never the year.
Commit: "Type local date-times and validate the calendar".

## 3. The cases
Runner with `-run 'valid/datetime/*' -run 'valid/local-*' -run 'invalid/datetime/*' -run 'invalid/local-*'
-run valid/array/array -run 'valid/spec-1.0.0/local-*' -run 'valid/spec-1.0.0/offset-*'`. The judge saw valid
array/array, datetime/local, datetime/leap-year, datetime/edge, spec local-date-time-0 fail and invalid datetime/feb-29,
no-secs, second-trailing-dot, second-trailing-dotz, local-date/feb-29, local-datetime/feb-29, local-datetime/no-secs,
local-time/no-secs, local-time/trailing-dot accepted. Paste the summary before and after.

## Verify (paste)
`wolf test .`; step 3's lines; `./test.sh; echo "exit=$?"` (C6 still ok). Stop.
