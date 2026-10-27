# tomlq v3 — the third judge (2026-10-27, from a fresh clone at `fc246b4`, 0.1.0; the reviewer's own 68-probe battery)

**Verdict: READY in substance, NOT YET PUBLIC.** The grade is real and reproduced from a fresh clone; three behaviours
and four repository nits stand between this tree and `github.com/wolffe-lang/tomlq`. One more closeout (13) does them.

## The gates, from a fresh clone (`~/lanes/tqj1/tomlq`)
`wolf build main.lu -o tomlq` 0, no warnings · `wolf fmt --check *.lu` 0 · `wolf test .` 11 passed · `./test.sh` 32 rows,
`All rows passed.`, exit 0 (the corpus fetched by `tools/fetch-corpus.sh` at `ff49d109`) · `./tomlq --spec toml-test/tests`
**valid 208/208, invalid 501/501** · `tomlq 0.1.0 (built with wolf 0.2.34)`.

## The battery (`~/lanes/tqj1/probes/battery.py`; every expectation written by the reviewer from the TOML 1.0 text, not
pasted from tomlq): **65 of 68.** Twenty valid documents (dotted keys, inline tables, arrays of tables with a sub-table,
every string form and escape, the line-ending backslash, all integer bases and the i64 bounds, floats with inf/nan, every
date-time kind, quoted/literal/unicode keys, CRLF, empty and comment-only documents, `[a.b]` then `[a]`, a super-table after
`[[…]]`), six tagged-type checks, nineteen invalid documents (duplicates, a bare CR, a control character, a NUL, invalid
UTF-8, leading zeros, an impossible hour, February 30, an extended inline table, `[[a]]` then `[a]`, overflow, a bad escape,
two values on a line, dotted into a value), three robustness probes, nineteen CLI rows. Every invalid document is refused
with `tomlq: -:LINE:COL: …` on stderr, exit 2, nothing on stdout; a 3,000-deep array and a 2,000-deep inline table neither
crash nor hang.

### The three that did not hold
1. **A long string is quadratic.** One basic string of 100 KB parses in 0.5 s, 200 KB in 2.5 s, 400 KB in 12.6 s (×4 per
   doubling); 2 MB did not finish in 20 s (≈ 5 min by the curve). Ten thousand 100-byte strings parse in 0.27 s, so it is
   the per-string build (`strbuf.push_str` — `b.s += s` copies, wolf-lang#298 — one byte at a time in the lexer's string
   reader), not the document size. README's *Known limits* names only the many-keys table. **Fix or name it**: the lexer
   should take a string without escapes as one slice of the source (`src[start..end]`) and push escape-free runs, not bytes.
2. **A missing PATH exits 1 in silence.** `tomlq nope doc.toml` → exit 1, nothing on stderr. The README promises the exit
   code; the user gets no sentence. Wanted: `tomlq: nope: not found` (and for a path into a scalar, `tomlq: a.b: not a
   table`), exit 1.
3. **A space-separated date-time is normalised.** `sp = 1979-05-27 07:32:00Z` prints as `"1979-05-27T07:32:00Z"`; the
   README's *Plain JSON* says "Date-times as their text". Either keep the text or say "normalised to `T`" — the reviewer
   prefers the sentence (the normalisation is what the corpus compares), so this is a README line.

### Recorded, not faults
- A UTF-8 BOM is refused as `-:1:1: empty key`. TOML 1.0 does not mention a BOM and the corpus has no case; most parsers
  skip one. Name it under *Known limits* (or skip the three bytes — a six-line change; the reviewer would take it).
- Array indexing is `p[1].n` (works); `p.1.n` is simply not found. The README's *Usage* never shows the index form —
  add one example.
- `tomlq --json - doc.toml` reads stdin and ignores `doc.toml` silently. A second operand should be a usage error, exit 2.

## The repository, for publishing
- `LICENSE` is the Apache-2.0 text verbatim (sha256 `cfc7749b…` matches apache.org). No absolute paths, no names, no trailers
  in 41 commits; `prompts/` tracked; `.gitignore` right (binary, dSYM, the corpus, WOLF-NOTES, scratch).
- **`SPEC.md` is a byte-identical copy of `README.md`** (closeout 12 made it so). A public repo should not carry the same
  file twice: delete `SPEC.md` and its row in the Files table (the README *is* the specification the build followed; say so
  in one line under the banner), or restore the original specification text if it ever differed.
- **`doc/` holds generated HTML for the standard library's modules** (`module.std.bytes.html` …), committed by accident in
  `b5d4b6e`. Delete it and add `doc/` to `.gitignore`.
- The README: `--raw`, `--only SUBDIR` and `--spec-verbose` appear in the usage block and nowhere else — one sentence each
  under *Usage*; the stdin example is given twice (the first "Parse and emit plain JSON" already reads `-`) — drop one; add
  the index example; the *Known limits* gain the long-string curve (if not fixed) and the BOM.
- Unit tests: 11 is thin for a parser, but the corpus is the test and `test.sh` compares bytes; acceptable as published.

## Closeout 13 (one session, `prompts/close13-the-judge-s-fixes.md`), then publish
The three behaviours (1 fixed or named with its curve; 2 the message; 3 the README line), the BOM skipped or named, the
second-operand usage error, `SPEC.md` and `doc/` removed, the README edits, `./test.sh` rows for each behaviour changed
(a 400 KB string under `tools/memrun.sh` with a time bar if fixed; the missing-PATH message; the second operand; the BOM),
the CHANGELOG's 0.1.1 entry, `VERSION`/`--version` 0.1.1. The reviewer re-runs the battery from a fresh clone and, on
68/68 and the repository clean, the maintainer publishes `wolffe-lang/tomlq` (Apache-2.0, the banner as mk's and spell's).
