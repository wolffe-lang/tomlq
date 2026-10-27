# tomlq — nudge 11: closeout 10 is not done at 481/501. Finish it. The stopping rule changes.

You wrote "given the complexity, I'll revert this change and note that the remaining failures are definition-rule
issues". That is not allowed. **The only acceptable end states are 501/501 and 208/208, or a pasted case with the exact
TOML rule you believe toml-test is wrong about.** "Complex" is not a reason. Every rule below is one small edit.

## 0. The five valid failures are YOURS, not pre-existing
`git log` says so: `cd24832` (19:00) broke `float/exponent`, `float/exponent-upper`, `spec-1.0.0/float-0` (`-1e-1` → -10);
`f67954b` (19:16) broke `comment/everywhere`, `comment/tricky` (a bare `1979-05-27` typed `datetime`, must be `date-local`).
Fix both first: unit tests `-1e-1 → -0.1`, `1E+2 → 100.0`, `6.626e-34`; a bare date → kind 8 (`date-local`); a value followed
by ` # comment` keeps its type. Commit "Fix negative exponents and bare dates". Runner: `valid 208 passed`.

## 1. The rule you reverted, done right: a dotted-key table is its own kind
Your revert happened because you rejected dotted keys into header-defined tables — the wrong target. Give tables created
by a dotted key their own `defined_by` **5** (legend: 0 root, 1 implicit by a header path, 2 inline, 3 explicit `[header]`,
4 `[[header]]` element, 5 dotted key). The parser already has `p.current` (the table of the current header). Add
`block: int` to `Node`, and `p.block: int` incremented at every `[header]`/`[[header]]`; a node created by a dotted key
records `p.block`. Then in `may_define` on an existing table `kid`:
- `how` 3 or 4 and `kid.defined_by == 5` → "table defined by dotted keys" (`table/append-with-dotted-keys-01, -02, -03,
  -08`, `table/duplicate-key-04, -05`). Also refuse when ANY ancestor on the header path has `defined_by 5`: apply
  `may_define` with `how 1`-style descent but refusing `defined_by 5` ancestors for headers (walk the segments; the
  intermediate segments of a header are `how 6`: refused on `defined_by 5` and on `closed`, otherwise allowed).
- `how` 1 or 5 and `kid.defined_by == 5` and `kid.block != p.block` → "key already defined" (a later block may not extend
  it); same block → allowed.
- `how` 3 and `kid.defined_by == 3` → "table defined twice" (`table/redefine-02, -03`, `spec-1.0.0/table-9-0, -9-1`); `how 3`
  and `defined_by 1` → allowed once, set 3 (you have this).
- `kid.closed` (an inline table, or anything inside one) and `how` is 1, 3, 4 or 5 → "inline table is closed"
  (`inline-table/duplicate-key-03`, `overwrite-02, -07, -08`, `spec-1.0.0/inline-table-2-0`). Check `closed` BEFORE the
  kind checks, for tables and values alike.
- `how` 4 and `kid` is a table (kind 0) → "array of tables conflicts" (`array/tables-01`); `how` 4 and `kid` is an array
  whose first element is not a table, or that was created by `a = [...]` (a value array: mark arrays from a value with
  `defined_by 2`, from `[[header]]` with 4) → refuse (`array/extend-defined-aot`, `array/extending-table`); `how` 3 on an
  array → refuse (you have this).
Commit "Close dotted-key tables to later headers and blocks".

## 2. Headers on one line
`table/newline-01`, `-03`: inside `[` … `]` a newline before `]` is an error "unterminated table header" (the key must be on
the header's line). Commit "Refuse a newline inside a table header".

## 3. Verify (paste all three; stop only on 501/501 and 208/208)
`wolf test .`; `toml-test/toml-test-runner test -toml 1.0 -decoder="$PWD/tools/decoder.sh" -timeout 5s -parallel 4 | tail -4`;
`./test.sh; echo "exit=$?"`. If any case remains, paste the case's TOML and the toml-test rule you dispute — nothing else
ends the closeout. Then stop.
