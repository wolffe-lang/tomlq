# tomlq closeouts — the rules for every session (read before the prompt)

1. **One prompt per session.** Do only that prompt's items, in its order, and stop after its Verify. Do not start the next.
2. **Red first.** Before changing tomlq's code for an item, add its rows (a `test.sh` row or a unit test in
   `tomlq_test.lu`) and run them: they must FAIL, and you paste the failing lines. Then fix, rebuild, re-run.
3. **Small edits.** At most ~60 lines per edit; never rewrite a whole file; a new file over 60 lines is written in parts.
   No probe programs under /tmp; a scratch file lives in this directory and is deleted before you stop.
4. **Rebuild before every test:** `wolf build main.lu -o tomlq`. When it says
   `cannot compile this yet — <construct> @A..B`, find the bytes with
   `for f in *.lu; do python3 -c "import sys;b=open('$f','rb').read();print('$f',repr(b[A:B]))"; done` (A and B the
   numbers), change that one construct, rebuild. Never redesign working code to get around it.
5. **Memory.** Never run `tomlq` on a generated or large input except as `bash tools/memrun.sh 2048 20 ./tomlq …`
   (a run once reached 37 GB on this Mac). The corpus cases are small; they may run directly.
6. **The grade is toml-test's.** `./test.sh` runs toml-test's own runner (`toml-test/toml-test-runner`) through
   `tools/decoder.sh`. Never edit the runner, the corpus, the decoder wrapper's exit mapping or a row's expected bytes to
   make a row pass. If a case cannot pass without a construct wolf refuses, name the case and the construct and leave it
   failing.
7. **Commits.** After each item whose rows pass: `git add -A && git commit -m "<one imperative line>"`. The commit lines in
   the prompt are the shape to aim for; once edits exist, only `git add`/`git commit` — never undo, stash or retype finished
   work to make commits match. Work that interleaved goes in one honest batch commit whose message lists what it holds.
   No `git push`, no remote, no tags.
8. **Do not edit `prompts/`** (it is the record), the corpus, or `tools/memrun.sh`.
9. **Paste, do not summarise.** Each Verify lists commands; paste their output whole. Say plainly what still fails.
