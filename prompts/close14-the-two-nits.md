# tomlq — closeout 14: the fourth judge's two nits, and the fifth judge's one (0.1.2)

Read `prompts/judge-v3-r4.md` §"Two nits" and `prompts/close-rules.md`. The only end state: `./test.sh` every row ok with the
three new rows, `./tomlq --version` → `tomlq 0.1.2 (built with wolf 0.2.34)`, a clean tree.

## 1. Rows first (red), commit "tests: stderr ends in one newline; --spec refuses a non-corpus; PATH alone is usage (red)"
- `N1`: `./tomlq nope .l1.toml 2>&1 >/dev/null | od -c | tail -2` shows exactly ONE `\n` at the end (compare the byte count:
  the message plus one newline).
- `N2`: `mkdir -p .notcorpus && ./tomlq --spec .notcorpus; echo $?` → stderr `tomlq: .notcorpus: not a toml-test corpus (no
  files-toml-1.0.0)`, exit 2, nothing on stdout.
- `N3`: `./tomlq k; echo $?` (a PATH and no FILE) → the usage lines on stderr, exit 2 — today it prints `tomlq: not implemented`
  (main.lu:637, the fall-through of the argument dispatch).

## 2. The fixes, one commit each
1. Find where errors are printed in `main.lu` (an `eprint` of a message that already ends in `\n`, or a message built with a
   trailing newline); make every error one line, one newline. Commit "Print an error as one line".
2. In `spec_run`, when `DIR/files-toml-1.0.0` cannot be read, print the sentence above and return 2 before counting anything.
   Commit "Refuse a --spec directory that is not a corpus".
3. In the dispatch, the final `return not_implemented()` becomes `return usage_err()`; delete `not_implemented`. Commit
   "A PATH without a FILE is a usage error".
4. README `## Tests`: "32 rows in test.sh" → the count `./test.sh | grep -c '^ok'` prints after §1 (37 today + 3 = 40). Commit
   "README: the row count".
5. `VERSION`/`--version` 0.1.2; CHANGELOG `## 0.1.2 (<today>)` with the three lines. Commit "Release 0.1.2".

## Verify (paste): `wolf build main.lu -o tomlq && wolf fmt --check *.lu && wolf test . | tail -1`; `./test.sh; echo "exit=$?"`;
`git status --short`. Stop.
