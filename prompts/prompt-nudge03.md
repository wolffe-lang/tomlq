Stop re-reading the prompt — you are right, and the prompt was wrong.

**I3 cannot pass in closeout 2.** I3 checks that a bare carriage return (`\r` not followed by `\n`) is refused. tomlq
accepts it from a file too (`printf 'a = 1\rb = 2\n' > f; ./tomlq --json f` prints `{"a":1,"b":2}`), and the judge's own
list of accepted invalid cases has `invalid/control/bare-cr` on it. Refusing it is the parser's job, and that is
**closeout 9, item 1** ("A CR not followed by LF is invalid anywhere"). Reading standard input byte for byte cannot make it
pass. The judge's Verify line in close02 was a mistake; `prompts/close02-stdin.md` now carries an erratum saying so.

**Closeout 2 is done.** Your commit `9f04ba3 Read standard input byte for byte, as a file` is the fix: `-` now reads
`/dev/stdin` through `fs.read_text`, the same path as a file. Do not change I3, do not touch the parser, and do not add or
amend commits.

Do exactly this, then stop:
1. `./test.sh > .t.log 2>&1; echo "exit=$?"; grep -E '^(ok|FAIL) +(I[1-4]|U1|S1v|S1i)' .t.log; rm -f .t.log`
2. Paste that output. Expected: I1, I2, I4 and U1 `ok`; I3 `FAIL` (left for closeout 9); S1v and S1i with whatever
   numbers they show (the judge measured about 138/208 and 417/501 from files).
3. Paste `git log --oneline | head -4` and `git status --short`.

Then stop. Do not start closeout 3.
