# tomlq — nudge 12: nine cases left (5 invalid, 4 valid you broke, 2 floats). Each is one rule below. Finish.

You wrote "given the complexity, I'll note that the remaining failures…" again. Nudge 11 forbade that sentence; it still
holds. The nine cases below are mapped to six rules, each a few lines. **Stop only at 501/501 and 208/208.**

## 1. Floats: stop computing them by hand (`comment/tricky` 1.11e1 → 11.1, `spec-1.0.0/float-0` 6.626e-34)
`parse_float_str` multiplies and divides parts in f64 and lands one ulp off. wolf-std has an exact parser:
`std/fmt/decimal` — `decimal.parse_float(s: str) -> f64 ! {parse, overflow}`. Keep your inf/nan branches, strip `_` and
a leading `+`, then return `decimal.parse_float(cleaned)` (map its errors to ParseError). Unit tests: `1.11e1 → 11.1`,
`6.626e-34`, `-2E-2 → -0.02`, `5e+22`. Commit "Parse floats exactly through decimal.parse_float".

## 2. Header paths create implicit tables, never dotted-key ones (`array/open-parent-table`, `table/array-implicit-and-explicit-after`)
`[[parent-table.arr]]` then `[parent-table]` is VALID: `parent-table` was created implicitly (defined_by 1) by a header
path and may be opened explicitly once. Every intermediate segment of BOTH `[header]` and `[[header]]` must go through
`or_resolve_for_header` (creates defined_by 1); none may call the dotted-key creator (defined_by 5). Check the `[[…]]`
path: it still calls the dotted creator for its intermediates.

## 3. A header may create a NEW sub-table under a dotted-key table (`spec-1.0.0/table-9`, `table/array-within-dotted`)
`[fruit]` / `apple.color = "red"` / `[fruit.apple.texture]` is VALID; so is `[[fruit.apple.seeds]]`. The rule refuses only
a header whose LAST segment names an existing defined_by-5 table (`[fruit.apple]`). Intermediate segments may pass
through a defined_by-5 table. In `or_resolve_for_header`, passing through is allowed; the `(how == 3 || how == 4) &&
defined_by == 5` refusal applies to the last segment only.

## 4. Dotted keys descend only into tables they may extend (`append-with-dotted-keys-01`, `-02`, `-08`, `inline-table/overwrite-07`)
Call `may_define(…, how 1)` at EVERY segment of a dotted key, the first included (today only the last is checked). In it:
- the segment's table is `closed` (an inline table or anything inside one) → refuse (`-01`: `a.b.c = {z=9}` then
  `a.b.c.t = "str"`; `-02` one level deeper);
- the segment's table has defined_by 3 or 4 (made by a header) and we are in a different block than it → refuse
  (`-08`: `[a.b.c]` then `[a]` / `b.c.t = "str"`);
- the segment names an ARRAY: descend only into an array of tables (defined_by 4); a value array (`x = [{…}]`,
  defined_by 2) refuses (`overwrite-07`: `inner.table = [{}], inner.table.val = "bad"`).

## 5. Headers never enter a value array (`array/extending-table`)
`a = [{ b = 1 }]` then `[a.c]`: `or_resolve_for_header` on an array with defined_by 2 refuses "array of tables conflicts";
only defined_by 4 arrays yield their last element.

## 6. Verify (paste all three; stop only on 501/501 and 208/208)
`wolf test .`; `toml-test/toml-test-runner test -toml 1.0 -decoder="$PWD/tools/decoder.sh" -timeout 5s -parallel 4 | tail -4`;
`./test.sh; echo "exit=$?"`. Commits per rule ("Resolve header paths as implicit tables", "Descend dotted keys only where
they may extend", "Refuse headers into value arrays"). If a case remains, paste its TOML and the toml-test rule you
dispute. Then stop.
