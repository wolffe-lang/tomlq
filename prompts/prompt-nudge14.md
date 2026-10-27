# tomlq — nudge 14: the cursor bug is one line, not a mystery. Stop re-reading; fix it, verify, commit, release.

You wrote "Wait, I think I see the issue" four times in a row with the same sentence and no edit. That is a loop. The
loop ends here. Four valid cases regressed under your string rewrite — `string-4`, `string-7`, `multiline-quotes`,
`raw-multiline` (`toml-test/toml-test-runner … | tail -4` → `valid: 204 passed, 4 failed`) — and all four have ONE cause.

## 1. The cause, in `parse_multiline_basic_string` (lexer.lu, the "Check for closing """" block)
When the run of quotes at `i` is 4 or 5 long, your branch appends `n - 3` quotes to `result` and then advances
`c.pos = c.pos + 1` per quote and `c.pos = c.pos + 3` — but `c.pos` is still the RUN START (only the `n == 3` branch sets
`c.pos = i + 3`). So the cursor lands `n` bytes after the run start instead of after the quotes, the parser resumes in the
middle of the string, and the error is `key/value not followed by newline`. The fix is to position from `i`:
```
            } else if n == 4 || n == 5 {
                var j = 0
                while j < n - 3 {
                    result = result + "\""
                    j = j + 1
                }
                c.pos = i + n
                return result
```
(delete the two `c.pos = c.pos + …` lines; set `c.pos = i + n` once). Then check the `n == 3` branch also returns with
`c.pos = i + 3` (it does) and that `count_quotes` is called from a cursor at `i` (it is: `temp.pos = i`).
**Do the same in `parse_multiline_literal_string`** for `'''`: its closing branch must set `c.pos = i + n` after appending
`n - 3` apostrophes. Read only that block; change only those lines.

## 2. Verify (paste all; stop only at every number below)
`wolf build main.lu -o tomlq && wolf fmt --check *.lu && wolf test . | tail -1`;
`./tomlq --json toml-test/tests/valid/spec-1.0.0/string-4.toml` → `{"str":"\"This,\" she said, \"is just a pointless statement.\""}`;
`toml-test/toml-test-runner test -toml 1.0 -decoder="$PWD/tools/decoder.sh" -timeout 5s -parallel 4 | tail -4` →
`valid 208/208`, `invalid 501/501`; `./test.sh; echo "exit=$?"` → every row ok, L1–L5 included, `exit=0`.

## 3. Commit, one file at a time (the rows are already committed red at `403021c`)
- `git add lexer.lu && git commit -m "Read strings by slice, not by byte"`
- `git add main.lu && git commit -m "Name a failing PATH; refuse a second operand"`
- `git add parser.lu && git commit -m "Skip a leading byte-order mark"`
- `git add test.sh && git commit -m "tests: the L rows as the judge wrote them"` (if `git diff test.sh` is non-empty)
- `rm -f .bom.toml`
Then closeout 13's item 2.5 (the repository: `git rm -r SPEC.md doc`, `.gitignore` gains `doc/`, the README edits as listed
in `prompts/close13-the-judge-s-fixes.md`) and item 2.6 (`Release 0.1.1`). Paste `git log --oneline | head -8`,
`git status --short` (empty), `ls` (no SPEC.md, no doc), `./tomlq --version` → `tomlq 0.1.1 (built with wolf 0.2.34)`. Stop.
