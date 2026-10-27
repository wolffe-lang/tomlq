# tomlq v3 — the fourth judge (2026-10-27, from a fresh clone at `693366d`, 0.1.1; the same 68-probe battery)

**Verdict: READY. Publish.** Every finding of the third judge is fixed as asked, nothing regressed, the tree is clean.

## The gates, from a fresh clone (`~/lanes/tqj1/tomlq`)
`wolf build main.lu -o tomlq` 0, no warnings · `wolf fmt --check *.lu` 0 · `wolf test .` 11 passed · `./test.sh` **37 rows,
all ok, exit 0** (L1–L5 included; L1: the 400 KB string in 0.12 s) · the runner and `./tomlq --spec toml-test/tests` both
**valid 208/208, invalid 501/501** · `tomlq 0.1.1 (built with wolf 0.2.34)`.

## The battery: 68/68
The two lines the script still prints as FAIL are the reviewer's own stale expectations (the `--version` text now says 0.1.1;
the space-separated date-time is normalised to `T`, which the README now states). By hand, the new behaviours:
- a 2 MB basic string parses in **0.08 s** (was: not within 20 s); the quote runs at a multiline close are right
  (`"""a""""` → `a"`, `""""b"""` → `"b`, `"""c"""""` → `c""`, the literal twin likewise; six quotes refused as "too many
  closing quotes", exit 2);
- `tomlq nope FILE` → `tomlq: nope: not found`, exit 1; a step into a scalar → `tomlq: a.b.c.d: not a table`, exit 1;
- `tomlq --json - FILE` → `tomlq: unexpected operand: FILE` then the usage, exit 2;
- a leading BOM is skipped (`{"a":1}`, exit 0).

## The repository
`SPEC.md` and `doc/` gone, `doc/` ignored; the README carries the banner's new line ("The README is the specification the
build followed."), the index example, the normalisation sentence and the three option sentences; the Files table has no
`SPEC.md` row; `CHANGELOG.md` has the 0.1.1 entry; the LICENSE is the Apache text verbatim (`cfc7749b…`); no absolute paths,
no names, no trailers in 48 commits; the seven closeout-13 commits are one per fix as asked.

## Two nits for 0.1.2, not blocking
- Every error line on stderr is followed by an empty line (`tomlq: nope: not found\n\n`): the message carries its own
  newline and the printer adds one.
- `tomlq --spec DIR` on a directory that is not a toml-test corpus prints `tomlq: DIR/files-toml-1.0.0: not_found` (the
  error's name, not a sentence) and then `valid: 0/0 passed`, exit 0. It should refuse: `tomlq: DIR: not a toml-test corpus
  (no files-toml-1.0.0)`, exit 2.
Both are in `prompts/close14-the-two-nits.md` for whenever the next session runs; neither delays publication.

## Publishing (the maintainer's step)
`wolffe-lang/tomlq`, public, Apache-2.0, the description "A TOML 1.0 parser and query tool in wolf, written by the
wollf-v7sf3 model", trunk `693366d` pushed whole (the history is the record; `prompts/` tracked). The banner, LICENSE and
README are already in the shape mk's and spell's were published with.
