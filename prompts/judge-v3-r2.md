# tomlq v3 — judge, round 2 (2026-10-26, the orchestrator; the tree as left by completed01.md)

**Verdict: NOT READY. The five follow-ups were not completed.** Follow-up 1 left the value comparison and test.sh undone
(the session reverted `sort_keys_json` to whitespace stripping and kept every `tail -2 … PASS` step); follow-ups 2–4 moved
the grade a little; follow-up 5 ran although its first line says to stop when the grade is not green. Twelve closeout
prompts follow (`close01` … `close12`), one session each, in order. Each does one thing and starts by turning its rows red.

## How this was judged
A copy of the tree (not the working directory) at `~/lanes/orch-tomlq/judge-1026/`, built with wolf 0.2.34. The grader is
**toml-test's own runner**, built from the pinned corpus (`ff49d109`, `toml-test test -toml 1.0`), not tomlq's `--spec`:

| | tomlq's own `--spec` | toml-test's runner, input on stdin | toml-test's runner, input from a file |
|---|---|---|---|
| valid | 93/208 | 105/208 | **138/208** |
| invalid refused | 417/501 | 398/501 | **417/501** |

tomlq's count of valid cases is *lower* than the truth because it compares text; the stdin column is lower because `-`
stops reading at the first blank line (finding 2). The file column is the parser's real state.

## What holds
- `wolf build`, `wolf fmt --check`, `wolf test .` (one test) clean; `--spec` reads the 1.0 list (208/501).
- LICENSE is the Apache-2.0 text byte for byte (sha256 `cfc7749b…3d30`, identical to apache.org's file).
- C6 (the offset date-time row) is correct.

## What does not (each reproduced on the copy)
1. **No repository.** The directory is not a git repository; nothing is committed; `.lu-cache/` is not ignored.
2. **`-` stops at the first blank line.** `printf 'a = 1\n\nb = 2\n' | ./tomlq --json -` → `{"a":1}`. `read_input` loops
   `read_line()` and breaks on an empty line. 78 of the 208 valid cases print differently from stdin than from a file.
3. **Memory grows with the square of the input** (a regression since round 1, when 140,000 keys parsed in 0.35 s):
   arrays of inline tables peak at 438 MB for 1,000 rows, 11.6 GB for 5,000, and were killed at **37 GB** for 20,000 on this
   48 GB Mac; 140,000 flat keys were killed after 115 s. P1 cannot pass. `add_key_checked` and `find_child` copy the
   table's key list (`node_keys`) on every insertion.
4. **Dotted keys are flattened into one key.** `a.b = 1` → `{"a.b":1}` (C1); `parse_key` returns a dot-joined string, so a
   quoted `"a.b"` and a dotted `a.b` cannot be told apart. 29 valid cases miss keys for this reason.
5. **Arrays of tables fail on the second element:** `[[s]]` twice → `key already defined` (C3a–c, 12 valid cases refused).
6. **Non-ASCII text vanishes.** `"é\U0001F600"` decodes to `""` (C5); every multibyte string decodes to `""`, so
   Unicode keys collide (`key/case-sensitive` is refused). The emitter does not escape control characters: `"a\u0000b"`
   prints a raw NUL, so `--json` is not JSON (31 of the valid cases fail `json.load`).
7. **Numbers:** `0xff`, `0o17`, `0b101` and `1_000` all become `0`; floats print as written (`--json` prints `1e2`,
   `+0e2`, `1_0.5` — not JSON); `-inf` loses its sign (C7a/b).
8. **Date-times:** a local date-time is typed `datetime` (4 cases); `0001-01-01` prints as `1-01-01`.
9. **84 invalid documents accepted:** control characters (11), date-times (9), inline-table rules (18), table and dotted-key
   rules (24), key shapes and newlines (16), number shapes (8).
10. **The CLI:** every error goes to stdout, not stderr; a scalar PATH prints JSON (`"x"`, C2a) where the spec says raw;
    C4 reads `-:2:6: key already defined` (want `-:2:1: key a already defined`); no arguments prints usage and exits 0;
    an unknown option prints `not implemented`; `--version` lacks the wolf version.
11. **The harness:** `--spec` compares text; `test.sh` prints PASS on every step whatever happens (it exits 0 at 93/208);
    one unit test for the whole parser.
12. **The README** has no "Built by wollf" banner, no example output, claims behaviour that is not true ("Datetimes are
    zero-padded and normalized", "`-` as FILE reads stdin"), quotes the self-grade, and says "Copyright 2026 tomlq
    authors" where spell and mk say "Licensed under the Apache License 2.0 (`LICENSE`)". No SPEC.md (spell and mk ship the
    spec as SPEC.md). WOLF-NOTES.md is the harness's notes, not part of the tool (neither spell nor mk ships it).

## Safety
P1 once climbed to 37 GB here. Every large input — P1, P2, scaling probes — runs only through `tools/memrun.sh 2048 20 …`
(close01 adds it); never run `tomlq` on a generated file without it.

## The gate for READY
`./test.sh` exits 0 — every row: fmt, build, unit, C1–C7, I1–I3, K1, E1–E3, V1, S0, S1v `208/208`, S1i `501/501`
(toml-test's runner), U1 (stdin = file on every valid case), J1 (`--json` is JSON on every valid case), P1, P2 — with
the unit tests each closeout adds; the README rewritten with the banner and every example pasted from the binary; the
history committed as it went. Then the maintainer creates `wolffe-lang/tomlq` and pushes (a public step), as for spell
and mk.

## The closeouts, in order
| prompt | does | rows it turns green |
|---|---|---|
| close01 | the repository, the guard, the decoder wrapper, the corpus fetch, an honest test.sh (no tomlq code) | fmt, build, unit; the rest red and named |
| close02 | stdin read byte for byte | I1, I2, I3, U1; S1 rises to the file column |
| close03 | the memory blow-up | P1, P2 |
| close04 | UTF-8: escapes decoded, multibyte kept, JSON escaped | C5, part of J1 |
| close05 | keys as lists of segments | C1, C2b, K1 |
| close06 | arrays of tables | C3a–c |
| close07 | integers and floats in both forms | C7a, C7b, J1 |
| close08 | date-time kinds and the calendar | — (S1 cases) |
| close09 | invalid: control characters, number and key shapes | — (S1i) |
| close10 | invalid: the definition rules | — (S1i) |
| close11 | the CLI: stderr, raw scalars, messages, usage, `--version`, an honest `--spec` | C2a, C4, E1–E3, V1, S0 |
| close12 | the release: README with the banner, SPEC.md, CHANGELOG, Files | (all) |
