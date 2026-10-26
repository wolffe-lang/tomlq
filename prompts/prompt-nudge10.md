# tomlq — nudge 10: finish closeout 10 (the definition rules). Nothing else first.

You stopped at "partially complete" with 27 invalid cases accepted and 5 valid cases broken. Closeout 10 is not done until
`invalid 501/501` and `valid 208/208`. The work below is bounded: one flag, one function, five call sites. Do it in this order,
one small edit at a time, `wolf build main.lu -o tomlq` after each, and commit as each rule lands.

## 1. The tree: a `closed` flag and a legend (tree.lu)
Add `closed: bool` to `Node` (false everywhere a Node is built). Put this legend above `table_node` and in README §5:
`defined_by` 0 root; 1 implicit (created by a header path or by a dotted key); 2 inline table; 3 explicit `[header]`;
4 array-of-tables element. Line 105's `table_node(mut p.arena, 3)` for a `[[header]]` element becomes `4`. The explicit
`[header]` path (the `else` branch after line 108) must mark the table it opens: if the table already exists with
`defined_by` 1, set it to 3 (an implicit table may be opened explicitly once); if it is already 3, refuse (`table/redefine-02`,
`redefine-03`, `super-twice`, `spec-1.0.0/table-9-0`, `-9-1`). A table created by a key/value line's dotted key, and every
sub-table under it, is `closed = true` to later headers: `[a]` or `[a.b]` after `a.b.c = 1` in a table block is refused
(`table/append-with-dotted-keys-01..04`, `-08`), but another dotted key in the SAME table block may extend it. When
`parse_inline_table` returns, set `closed = true` on the inline table and recursively on every table inside it
(`inline-table/overwrite-02`, `-05`, `-07`, `-08`, `duplicate-key-03`, `spec-1.0.0/inline-table-2-0`).

## 2. One function decides (parser.lu)
`fn may_define(p: Parser, parent: int, key: str, how: int) -> ! {ParseError(int, int, str)}` where `how` is 1 dotted key,
2 inline, 3 `[header]`, 4 `[[header]]`, 5 a plain `key = value`. Look the key up in `parent` and refuse with the reason:
- the key holds a value or an array that is not an array of tables → "key already defined" (`table/duplicate-key-01`, `-04`,
  `-05`, `-09`, `-11`, `-13`; `array/extending-table`);
- the parent is `closed` and `how` is 3 or 4 → "table is closed" (the dotted-key and inline rules above);
- the key holds a table with `defined_by` 3 and `how` is 3 → "table defined twice";
- the key holds an array of tables and `how` is 3, or holds a table/value and `how` is 4 → "array of tables conflicts"
  (`array/extend-defined-aot`, `array/tables-01`);
- `how` is 5 and the key exists at all → "key already defined".
Call it at: the key/value line (how 5), the dotted-key descent at line ~196 (how 1), the inline-table key (how 2, then
how 5 for its value), the `[header]` path (how 3 at the LAST segment, how 1 at the intermediate ones), the `[[header]]` path
(how 4 at the last). Delete the seven scattered `"key already defined"` returns as each site moves to `may_define`.
`table/newline-01`, `-03`: a header's `]` must be followed by a newline or EOF on the same line — check `require_newline_or_eof`
runs before any key is read on that line.

## 3. The five valid cases you broke today (closeout 7/8 regressions; fix before verifying)
- `float/exponent`, `float/exponent-upper`, `spec-1.0.0/float-0`: `-0.1` came out as `-10`: a negative mantissa with an
  exponent, e.g. `neg = -1e-1`. Read the sign, then the digits, then the exponent (`e`/`E`, its own sign), and divide, not
  multiply, for a negative exponent. Unit test `-1e-1 → -0.1`, `6.626e-34`, `1E+2 → 100.0`.
- `comment/everywhere`, `comment/tricky`: `1979-05-27` with no time is `date-local` (kind 8), not `datetime`; and a value
  followed by a `# comment` must still be typed by what precedes the comment. Unit test each.

## Verify (paste all three)
`wolf test .`; `toml-test/toml-test-runner test -toml 1.0 -decoder="$PWD/tools/decoder.sh" -timeout 5s -parallel 4 | tail -4`
with `valid 208 passed, 0 failed` and `invalid 501 passed, 0 failed` (or every remaining case named with the rule it
breaks and why the rule cannot apply); `./test.sh; echo "exit=$?"`. Commit "Decide every definition through may_define"
and "Fix negative exponents and comment-trailed dates". Stop.
