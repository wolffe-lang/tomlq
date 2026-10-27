# tomlq — closeout 14: the fourth judge's two nits (0.1.2)

Read `prompts/judge-v3-r4.md` §"Two nits" and `prompts/close-rules.md`. The only end state: `./test.sh` every row ok with the
two new rows, `./tomlq --version` → `tomlq 0.1.2 (built with wolf 0.2.34)`, a clean tree.

## 1. Rows first (red), commit "tests: stderr ends in one newline; --spec refuses a non-corpus (red)"
- `N1`: `./tomlq nope .l1.toml 2>&1 >/dev/null | od -c | tail -2` shows exactly ONE `\n` at the end (compare the byte count:
  the message plus one newline).
- `N2`: `mkdir -p .notcorpus && ./tomlq --spec .notcorpus; echo $?` → stderr `tomlq: .notcorpus: not a toml-test corpus (no
  files-toml-1.0.0)`, exit 2, nothing on stdout.

## 2. The fixes, one commit each
1. Find where errors are printed in `main.lu` (an `eprint` of a message that already ends in `\n`, or a message built with a
   trailing newline); make every error one line, one newline. Commit "Print an error as one line".
2. In `spec_run`, when `DIR/files-toml-1.0.0` cannot be read, print the sentence above and return 2 before counting anything.
   Commit "Refuse a --spec directory that is not a corpus".
3. `VERSION`/`--version` 0.1.2; CHANGELOG `## 0.1.2 (<today>)` with the two lines. Commit "Release 0.1.2".

## Verify (paste): `wolf build main.lu -o tomlq && wolf fmt --check *.lu && wolf test . | tail -1`; `./test.sh; echo "exit=$?"`;
`git status --short`. Stop.
