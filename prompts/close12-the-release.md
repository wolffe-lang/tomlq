# tomlq — closeout 12 of 12: the release

Read `prompts/judge-v3-r2.md` (finding 12) and `prompts/close-rules.md`. This session writes no `.lu` code. **First run
`./test.sh; echo "exit=$?"`. If it does not print `All rows passed.` and `exit=0`, stop and paste it.**

## 1. README.md, rewritten in parts (≤60 lines per edit)
Every example below is a command you run in this session and its output pasted unchanged — no example from memory. Follow
spell's and mk's layout:
1. The banner, verbatim, as the first lines:
   ```
   > **Built by wollf.** This program was written by [wollf-v7sf3](https://huggingface.co/wolffe-lang/wollf-v7sf3),
   > a 27B model trained to write wolf, driven through opencode by the prompts in `prompts/`, with a human
   > reviewer judging each phase and writing the next. Every claim below is pasted from the binary; the test
   > script is the reason to trust it.
   ```
2. `# tomlq`, then two sentences: what it is (a TOML 1.0 parser and query tool in wolf) and how it is graded (toml-test's
   own runner, the counts in "The grade").
3. **Install:** `wolf build main.lu -o tomlq`; "Requires wolf 0.2.34 (https://github.com/wolffe-lang/wolf-lang)".
4. **Usage:** `./tomlq --help` pasted.
5. **Examples:** one each for `--json`, `--tagged`, a PATH (raw scalar), a PATH to a table, `--keys`, `--len`, `-` on
   stdin, and an error (C4) with its exit status — commands and outputs pasted.
6. **Exit codes:** 0 ok; 1 a missing path or a failing spec case; 2 a syntax or usage error.
7. **The grade:** the S1 lines from `./test.sh`, the corpus commit `ff49d109861c1ad25af53f687f2aef19ab650600`, and how to
   reproduce it (`bash tools/fetch-corpus.sh` then the runner line from test.sh).
8. **Plain JSON:** keys in document order; `inf`, `-inf`, `nan` as strings; floats always have a `.` or an exponent;
   date-times as their text.
9. **Known limits:** TOML 1.1 is not graded; a single table with tens of thousands of keys parses in time that grows with the
   square of its size (the duplicate-key check scans the table; wolf 0.2.34's `Map` is too costly to index it — wolf-lang#972); anything else test.sh does not cover that you know of. Nothing else.
10. **Tests:** the commands; how many rows test.sh has and how many unit tests `wolf test .` runs (counted, pasted).
11. **Measured numbers:** the P1 and P2 lines from test.sh (size, seconds, peak MB) and the machine (this Mac).
12. **Files:** a table of every tracked file and what it holds (`git ls-files`).
13. The last line: `Licensed under the Apache License 2.0 (`LICENSE`).`
Commit "Rewrite the README for the release".

## 2. The rest
- `SPEC.md`: `cp ../../README.md SPEC.md` (the specification this was built from, as spell and mk ship it). Commit "Add the
  specification".
- `CHANGELOG.md`: `## 0.1.0 (YYYY-MM-DD)` — what it does, the grade (both S1 counts) and the corpus commit; no other claim.
  Commit "Write the 0.1.0 changelog".
- `git status --short` prints nothing; `prompts/` is tracked; `WOLF-NOTES.md` and `toml-test/` are not.

## Verify (paste)
`./test.sh; echo "exit=$?"`; `./tomlq --version`; `git log --oneline`; `git ls-files`; `head -n 8 README.md`. The
maintainer creates the repository and pushes; do not run `git remote` or `git push`. Stop.
