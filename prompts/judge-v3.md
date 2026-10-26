# tomlq v3 — judge (2026-10-25 night, the orchestrator; the tree as left by completed00.md)

**Verdict: NOT READY for a public release. Five follow-up prompts (`followup-01` … `-05`), one per session, in order.**

## What holds
- `wolf build` 0, `wolf fmt --check` clean, `wolf test .` 1 passed; 2,811 lines in six modules (lexer 1,370, main 690,
  parser 332, emit 205, tree 190, the test 24). Definition of Done 4 holds: no `std.json`, the arena tree, no `+=` in the
  emitter. P1 holds: a 9.99 MB document (140,000 keys) in 0.35 s.
- The corpus is cloned at `ff49d109` and the runner walks it: 83/266 valid, 387/511 invalid as the session reported.

## What does not (each reproduced by hand from the README's own rows)
1. **`-` is not stdin.** Every row that pipes a document fails before parsing: C1, C4, C5, C6, C7 all print
   `tomlq: -: not_found`, exit 2.
2. **Paths with the README's leading dot are not found.** `./tomlq .c.d file` → `path not found: .c.d` (C2); `'.s[1].h'`,
   `--len .s`, `--keys '.s[0]'` all `path not found` (C3). test.sh only ever queried bare names (`best-day-ever`), so the
   README's syntax (`.a.b`, `.s[1].h`) was never exercised.
3. **`--spec` ignores the 1.0 list.** The README grades *1.0* cases: `toml-test/tests/files-toml-1.0.0` names 208 valid and
   501 invalid; the runner takes all 266 / 511 on disk, 1.1 cases included, so the counts are the wrong denominator.
4. **The valid comparison is textual.** The session itself names "key ordering (JSON comparison is order-sensitive)" as a
   failure cause — toml-test twins are compared as values, not bytes; a runner that diffs text fails correct output.
5. **valid: 183 failures** by directory: spec-examples 85, table 55, key 49, inline-table 32, string 13, datetime 13,
   control 13, float 12, array 9, integer 8, comment 3, the rest 1–2. The session's own causes: dotted keys in table
   headers, escapes not decoded, datetime fields not zero-padded, key order.
6. **invalid: 124 accepted** by directory: table 35, key 28, inline-table 19, control 13, spec 8, float 5, datetime 4,
   array 4, integer 3, local-* 5. The session's own causes: array/table extension rules, control characters in strings and
   comments, calendar validation (Feb 29).
7. **test.sh is vacuous.** Every `--spec` step pipes through `tail -2` and prints `PASS` whatever the counts; the C1–C7
   rows are not in it; it would say "All tests passed" at 0/266. `wolf test .` holds one smoke test, not the per-escape,
   per-trimming-rule, control-character and Unicode tests M1 asked for.
8. **Not a release:** no git history (the v3 directory is not a repository), no LICENSE, the README is the spec's copy
   (not the tool's), no version flag, no CHANGELOG.

## The gate for READY
`./tomlq --spec toml-test/tests` → `valid: 208/208`, `invalid: 501/501` on the 1.0 list (or every miss named with its rule
and the corpus commit); `./test.sh` exits 0 only when every README row C1–C7 and P1 prints its expected bytes; `wolf test .`
with the M1/M2 unit tests; a tool README, LICENSE, `--version`; then the repository is created and pushed by the
maintainer (a public step), as spell and mk were.
