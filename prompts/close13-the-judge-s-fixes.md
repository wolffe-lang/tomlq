# tomlq — closeout 13: the third judge's fixes (0.1.1), then the tree is public

Read `prompts/judge-v3-r3.md` whole, README §Usage and §Known limits, and `prompts/close-rules.md`. The only acceptable end
states are `./test.sh` all rows ok with the five new rows, `wolf test .` green, the repository without `SPEC.md` and `doc/`,
and `./tomlq --version` → `tomlq 0.1.1 (built with wolf 0.2.34)`; or a pasted case with the rule you dispute. Nothing else
ends the closeout. "Beyond the scope" is not an end state.

## 1. Rows first (red), one commit "tests: the judge's five rows (red)"
In `test.sh` part 2, after the P2 row:
- `L1`: a 400,000-byte basic string (`python3 -c "print('s = \"' + 'x'*400000 + '\"')" > .l1.toml`) parses under
  `tools/memrun.sh 512 5` (5 seconds): `ok L1 400 KB string: memrun: rc=0 … secs=S` — red today (12.6 s).
- `L2`: `./tomlq nope .l1.toml` exits 1 AND prints exactly `tomlq: nope: not found` on stderr, nothing on stdout.
- `L3`: `./tomlq --json - .l1.toml < /dev/null` exits 2 with `tomlq: unexpected operand: .l1.toml` then the usage on stderr.
- `L4`: `printf '\xef\xbb\xbfa = 1\n' | ./tomlq --json -` prints `{"a":1}`, exit 0 (the BOM skipped).
- `L5`: `./tomlq a.b .l1.toml` where `a.b` points into a scalar (`a = 1`): exit 1, `tomlq: a.b: not a table`.
Paste the five red lines.

## 2. The fixes, one commit each
1. **The string reader takes slices.** In `lexer.lu`'s basic/literal string readers (and the multiline forms), scan for the
   closing quote and any `\\`; a run without escapes is appended as ONE slice `src[start..i]` (`strbuf.push_str` once per
   run), never byte by byte; an escape appends its decoded text and the scan continues. Unit test: a 400 KB string's value
   length; the existing escape tests unchanged. Commit "Read strings by slice, not by byte". L1 green.
2. **Named path failures.** Where a PATH lookup fails in `main.lu`, print `tomlq: PATH: not found` (the key absent at any
   step) or `tomlq: PATH: not a table` (a step into a scalar or array element that is not a table), exit 1. Commit "Name a
   failing PATH". L2, L5 green.
3. **One operand.** After the options, exactly one FILE|- operand; a second is `tomlq: unexpected operand: NAME` + usage,
   exit 2 (as `--bogus` is). Commit "Refuse a second operand". L3 green.
4. **The BOM.** If the document begins with EF BB BF, start at byte 3. Commit "Skip a leading byte-order mark". L4 green.
5. **The repository.** `git rm SPEC.md doc -r`; `.gitignore` gains `doc/`; README: delete the `SPEC.md` row and say under
   the banner "The README is the specification the build followed."; one sentence each for `--raw` (prints a scalar bare,
   the default; kept for scripts), `--only SUBDIR` (run one corpus subtree) and `--spec-verbose` (print each failing case's
   first differing path and both values); drop the second stdin example; add `$ ./tomlq 'p[1].n' doc.toml` → `2` under
   *Examples*; *Plain JSON*: "Date-times normalised: a space between date and time becomes `T`."; *Known limits*: remove
   nothing, add nothing unless a fix above was not possible (then its measured curve). Commit "README and tree for 0.1.1".
6. **Release.** `VERSION` 0.1.1 (and wherever `--version` reads it), CHANGELOG `## 0.1.1 (<today>)` with the five lines
   (strings by slice; named PATH failures; one operand; the BOM; the tree). Commit "Release 0.1.1".

## Verify (paste all; stop only at every row ok)
`wolf build main.lu -o tomlq && wolf fmt --check *.lu && wolf test . | tail -1`; `./tomlq --version`;
`./test.sh; echo "exit=$?"` (every row ok, L1–L5 included); `git status --short` (empty); `ls` (no SPEC.md, no doc). Stop.
