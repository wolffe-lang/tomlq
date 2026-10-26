# tomlq — closeout 11 of 12: the command line, and a `--spec` that agrees with the runner

Read `prompts/judge-v3-r2.md` (findings 10 and 11), README §3 (FR-1, FR-5, FR-11, FR-13) and §4, and
`prompts/close-rules.md`.

## 1. Rows first (red)
Add to `test.sh` part 2, after the U1/J1 lines and inside the same `if` (one edit):
```bash
  sv=$(./tomlq --spec toml-test/tests 2>/dev/null | awk '/^valid:/ {print $2}')
  si=$(./tomlq --spec toml-test/tests 2>/dev/null | awk '/^invalid:/ {print $2}')
  [ "$sv" = "$v" ] && [ "$si" = "$i" ] && pass "S0    tomlq --spec agrees with toml-test's runner ($sv, $si)" || fail "S0    tomlq --spec says $sv, $si; toml-test's runner says $v, $i"
```
Paste `./test.sh`'s C2a, C4, E1, E2, E3, V1, S0 lines (failing).

## 2. The fixes, one commit each
1. **Errors on stderr.** Every `tomlq:` message goes to stderr; only `--help` prints usage on stdout. Commit "Print errors
   on standard error".
2. **A scalar PATH prints raw** (FR-5): a string without quotes, a number or boolean in its `--json` form, a date-time as
   its text; a table or array as JSON. `--raw` stays as the same thing for scalars (say so in `--help`). C2a. Commit
   "Print a scalar at PATH raw".
3. **"already defined" names the key at its second definition:** `tomlq: -:2:1: key a already defined` (C4) — the line:col
   where the key's second definition starts, the key spelled as written (dotted keys with their dots). Commit "Name the key
   and point at its second definition".
4. **Usage.** No arguments: the usage below on stderr, exit 2 (E1). An unknown option: `tomlq: unknown option: --bogus`
   then the usage, on stderr, exit 2 (E2). A missing file: `tomlq: /nonexistent: no such file`, exit 2 (E3). `--version`:
   `tomlq 0.1.0 (built with wolf 0.2.34)`, exit 0, from a `VERSION` constant (V1). The usage text:
   ```
   usage: tomlq [--json | --tagged] FILE|-
          tomlq [--raw] PATH FILE|-
          tomlq --keys PATH FILE|- | --len PATH FILE|-
          tomlq --spec DIR [--spec-verbose] [--only SUBDIR]
          tomlq --help
          tomlq --version
   ```
   Commit "Refuse usage errors with exit 2".
5. **An honest `--spec`** (README §5's runner, FR-3, FR-11): for a valid case, read your `--tagged` output and the twin
   `.json` with your own JSON reader (no `std.json`) and compare them as values — object keys unordered; arrays in order;
   leaves by type and value: integers by numeric value, floats by `decimal.parse_float` value (`nan` equals `nan`),
   date-times after normalising `t`/space to `T` and `z` to `Z`, strings byte for byte. `--spec-verbose` prints a failing
   case's first differing path and both values. Exit 0 only when every case passes. Commit "Compare spec cases as values".

## Verify (paste)
`./tomlq --help`; `./tomlq; echo $?`; `./tomlq --version`; `./tomlq --spec toml-test/tests | tail -n 2`;
`./test.sh; echo "exit=$?"` — C2a, C4, E1, E2, E3, V1, S0 ok. Stop.
