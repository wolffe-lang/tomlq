# tomlq — follow-up 1 of 5: an honest harness (stdin, paths, the 1.0 list, value comparison)

Read `prompts/judge-v3.md` first, then README §4 (the CLI), §7.1 (the rows) and §7.2. Rules for this session: edit in
place, at most ~60 lines per edit, no whole-file rewrites, no probe programs under /tmp (a scratch file lives in this
directory and is deleted before you stop); rebuild with `wolf build main.lu -o tomlq` before every test; when `wolf build`
says `cannot compile this yet — <construct> @A..B`, resolve the byte range to its file with
`for f in *.lu; do python3 -c "import sys;b=open('$f','rb').read();print('$f',repr(b[A:B]))"; done` (A..B the numbers),
change that one construct, rebuild — never redesign working code. Nothing in this session changes the parser's results;
it makes the measurement true.

1. **`-` is standard input.** In `main.lu`, where the FILE argument is opened, `-` reads all of stdin instead
   (`io.stdin().read_all()` per WOLF-NOTES; the error prefix in messages is `-`, as C4 shows: `tomlq: -:2:1: …`).
   Verify: C1 `printf 'a.b = 1\n[c]\nd = "x"\n' | ./tomlq --json -` → `{"a":{"b":1},"c":{"d":"x"}}`.
2. **Paths as the README spells them.** `.c.d`, `.s[1].h`, `.s[0]`, `.a.b`, and the empty path `""` for the root: the path
   parser accepts a leading `.`, dotted segments, quoted segments (`."a b"`), and `[N]` indexes into arrays and arrays of
   tables. Missing path: nothing on stdout, exit 1 (C2's last line). Verify C2 and C3 byte for byte.
3. **The 1.0 list.** `--spec DIR` reads `DIR/files-toml-1.0.0` and runs exactly the cases it names (208 valid, 501
   invalid at corpus `ff49d109`); `--spec-all` (new) runs everything on disk; the summary prints the denominators.
4. **Compare values, not bytes.** For a valid case, parse your `--tagged` output and the twin `.json` into values and
   compare structurally: object keys unordered, `{"type","value"}` leaves compared by type and by value with toml-test's
   normalisations (integers by numeric value; floats by numeric value with `inf`/`-inf`/`nan` as themselves; datetimes
   compared after normalising `T`/space and the offset `Z`/`+00:00`; strings byte-exact). Write this comparison in
   `main.lu` (or a new `compare.lu`) over your own JSON reader — no `std.json`. `--spec-verbose` prints, per failing case,
   the first differing path and both values.
5. **test.sh tells the truth.** Replace the `tail -2 … PASS` steps: each README row C1–C7 runs its exact command and compares
   stdout and the exit status against the expected bytes (fail loudly with both shown); the `--spec` steps parse the
   `valid: N/D` and `invalid: N/D` lines and FAIL unless N = D (until then the script exits 1 — that is the point); P1
   times the 10 MB file (`python3` builds it in a scratch dir) and fails above 2 s.

**Verify (paste all):** `wolf fmt --check *.lu`; `wolf build main.lu -o tomlq`; C1–C7 by hand with their outputs; `./tomlq
--spec toml-test/tests` → the two counts on the 1.0 denominators (expect valid to RISE from 83 once key order is not a
failure); `./test.sh; echo $?` → 1 with the failing rows named. Stop.
