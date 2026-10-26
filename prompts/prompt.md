# tomlq — v3 (multi-phase, low give-away)

This build is delivered as **phases**, pasted one at a time. Do **only** the current
phase, make its **verification** pass, then stop and wait for the next. Keep earlier
phases working. One directory, one wolf module, one `main`.

---

### PHASE 0 — Setup & spec

First run `cp ../../README.md ./README.md && cp ../../../WOLF-NOTES.md ./WOLF-NOTES.md`,
then read both fully (WOLF-NOTES §2 on enums and `std.json`). Clone the corpus:
`git clone --depth 1 https://github.com/toml-lang/toml-test` and note its commit and
how it marks 1.0-only cases. Write `main.lu` parsing README §4's forms; `--help` → usage,
exit 0; otherwise `tomlq: not implemented`, exit 2. Decide your file layout and write it
at the top of `main.lu`.

**Verify:** `wolf build main.lu -o tomlq` warning-free; `./tomlq --help; echo $?` → `0`;
`wolf fmt --check *.lu`.

--- END PHASE 0 ---

---

### PHASE 1 — Strings (M1)

The cursor with line/col; all four string forms with their escapes and the multi-line
rules; `--tokens` printing one token per line. Tests for every escape, the trimming
rules, control characters, invalid Unicode.

**Verify:** `--tokens` on `toml-test/tests/valid/string/*.toml` shows every string
decoded; every `invalid/string/*.toml` makes `--tokens` fail with a line:col (list any
that do not yet).

--- END PHASE 1 ---

---

### PHASE 2 — Numbers, booleans, dates (M2)

Integer bases, `_`, leading zeros, range; floats, `inf`/`nan`; booleans; the four
date-time shapes validated and normalized.

**Verify:** `--tokens` over `valid/integer`, `valid/float`, `valid/datetime`,
`valid/bool`; the matching `invalid/` directories refused; `wolf test .` green.

--- END PHASE 2 ---

---

### PHASE 3 — Structure and `--json` (M3)

Key/values, dotted keys, `[tables]`, `[[arrays of tables]]`, inline tables, arrays,
comments, the definition rules; the arena tree; your JSON emitter (`--json`).

**Verify:** C1, C4; `--json` of twenty files across `valid/` reads back through
`python3 -c 'import json,sys; json.load(sys.stdin)'`.

--- END PHASE 3 ---

---

### PHASE 4 — The tagged form and `valid/` (M4)

`--tagged`; `--spec DIR` comparing against the `.json` twins after sorting keys on both
sides with your own code; `--spec-verbose`; `--only`.

**Verify:** `--spec toml-test/tests --only valid` passes every 1.0 case (print the count).

--- END PHASE 4 ---

---

### PHASE 5 — `invalid/` (M5)

Every 1.0 invalid case refused; each refusal names its rule in the message.

**Verify:** `--spec toml-test/tests` passes both halves (print both counts).

--- END PHASE 5 ---

---

### PHASE 6 — Queries, the CLI rows, test.sh (M6)

`PATH` queries, `--keys`, `--len`, `--raw`; C2, C3, C5, C6, C7; P1; `test.sh`.

**Verify:** `./test.sh; echo $?` → `0`; `wolf test .` and `wolf fmt --check *.lu` clean.
Paste the last lines, the counts, the corpus commit and the statuses.

--- END PHASE 6 ---
