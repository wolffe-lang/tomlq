# tomlq — closeout 7 of 12: integers and floats, read as values and printed as JSON

Read `prompts/judge-v3-r2.md` (finding 7), README §2.1 and FR-8/FR-9, and `prompts/close-rules.md`.

**The bugs:** `0xff`, `0o17`, `0b101` and `1_000` all become `0`; floats are kept as their source text, so `--json`
prints `1e2`, `+0e2` and `1_0.5` (not JSON) and `-inf` loses its sign (C7a, C7b).

**What wolf has (checked on this Mac):** `std.fmt.parse_int_base` and `str.to_int()` for integers;
`std.fmt.decimal.parse_float(s) -> f64 ! {parse, overflow}` (`"1e2"` → 100.0, `"-0.03"` → -0.03); and `"{v}"` on an f64
prints its shortest round-trip form (`100`, `-0.03`, `0.1`, `1.7976931348623157e+308`). The README's "wolf has no `f64`
literals" is wrong — `let a: f64 = 100.0` compiles; close12 corrects the README.

## 1. Tests first (red), one per edit
Integers: `0xDEADBEEF` → 3735928559; `0o755` → 493; `0b11010110` → 214; `1_000` → 1000; `+99` → 99; `-0` → 0;
`9223372036854775807` accepted, `9223372036854775808` refused; `0X1`, `0O1`, `0B1`, `+0x1`, `01`, `1__0`, `_1`, `1_` refused.
Floats: `1e2` → tagged `100`, JSON `100.0`; `3.1e2` → `310`/`310.0`; `-0.1` → `-0.1`; `1_0.5` → `10.5`; `+0e2` → `0`/`0.0`;
`-inf` → tagged `-inf`, JSON `"-inf"`; `nan`, `+nan`, `-nan` → tagged `nan`, JSON `"nan"`; `.5`, `1.`, `-.5`, `01.5`,
`1e`, `1.e2`, `1__0.5` refused. Paste `wolf test .` failing and `./test.sh`'s C7 and J1 lines.

## 2. The fix
- The lexer validates each form's shape first (underscores only between digits, the prefixes lowercase, no sign on a
  prefixed integer, no leading zeros), then converts: strip `_`, `parse_int_base` / `to_int`, range-checked; floats through
  `decimal.parse_float` (inf/nan by their words, sign kept). Store the value in the node (`i` or `f`), not the text.
- `--tagged` prints integers in decimal and floats as `"{v}"` (with `inf`, `-inf`, `nan` as words).
- `--json` prints integers in decimal; a float as `"{v}"`, with `.0` appended when that text has no `.`, `e` or `E`;
  `inf`/`-inf`/`nan` as the JSON strings `"inf"`, `"-inf"`, `"nan"`.
- PATH and `--raw` print a float's `--json` form. Commits: "Read integers in every base as values", "Read floats as values
  and print them as JSON numbers".

## 3. The cases
Runner with `-run 'valid/integer/*' -run 'valid/float/*' -run 'invalid/integer/*' -run 'invalid/float/*'
-run 'valid/spec-1.0.0/integer-*' -run 'valid/spec-1.0.0/float-*'`; the judge saw integer/literals, underscore,
float64-max, spec integer-1, integer-2, float/inf-and-nan, spec float-2 fail as values, and invalid integer/capital-bin,
capital-hex, capital-oct and float/leading-dot-neg, leading-dot-plus, leading-zero, leading-zero-neg, leading-zero-plus
accepted. Paste the summary before and after.

## Verify (paste)
`wolf test .`; step 3's lines; `./test.sh; echo "exit=$?"` — C7a and C7b ok; J1's count. Stop.
