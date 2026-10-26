# tomlq — closeout 5 of 12: a key is a list of segments

Read `prompts/judge-v3-r2.md` (finding 4), README §2.1 (keys, dotted keys, tables) and `prompts/close-rules.md`.

**The bug:** `parse_key` returns the segments joined with `.`, so `a.b = 1` adds one key named `a.b` (C1 prints
`{"a.b":1}`), and a quoted `"a.b"` (one segment containing a dot) cannot be told apart from `a.b` (two segments).
`add_key_checked` only descends when the first segment already exists.

## 1. Rows and tests first (red)
Add after the `C1` row in `test.sh` (one edit):
```bash
row K1 0 '{"k":{"a.b":1},"x.y":2}' '' "printf 'k.\"a.b\" = 1\n\"x.y\" = 2\n' | ./tomlq --json -"
row K2 0 '1' '' "printf 'a.\"b c\".d = 1\n' | ./tomlq '.a.\"b c\".d' -"
```
Unit tests (one per edit): `a.b.c = 1` makes tables `a` and `a.b`; `a.b = 1` then `a.c = 2` share table `a`;
`"a.b" = 1` is one key; `a . b = 1` (spaces around the dot) equals `a.b = 1`; `[x."y.z"]` opens table `y.z` inside `x`;
`a.b = 1` then `a.b = 2` is refused; `a = 1` then `a.b = 2` is refused. Paste `./test.sh` (C1, C2b, K1, K2 failing) and
`wolf test .` failing.

## 2. The fix
`parse_key` returns `List[str]` — each segment decoded (quoted segments may contain `.`). A key/value line walks the
segments: every segment but the last finds or creates a table (an implicit one, `defined_by` 0); the last adds the value or
refuses `key … already defined`. Table headers `[…]` and `[[…]]` take the same list (`or_create_table_for_path`,
`or_create_array_for_path`). The PATH parser (`navigate_path`) already reads `.a."b c"` segments — check it agrees.
Commits: "Return keys as segment lists", "Descend dotted keys through implicit tables".

## 3. The cases
The judge saw 29 valid cases miss keys for this cause: inline-table/key-dotted-01, -02, -03, -05, -06, -07; key/dotted-01,
-02, -03, dotted-empty, like-date, numeric-02, numeric-04, numeric-05; spec-1.0.0/inline-table-0, -1, -3, keys-1, keys-3,
keys-4, keys-5, keys-6, keys-7, table-2, table-3, table-8, table-9; table/array-within-dotted, table/names. Run the runner
with `-run 'valid/key/*' -run 'valid/inline-table/*' -run 'valid/spec-1.0.0/*' -run 'valid/table/*'` and paste the
summary before and after, and every case of this list that still fails with its message.

## Verify (paste)
`wolf test .`; step 3's lines; `./test.sh; echo "exit=$?"` — C1, C2b, K1, K2 ok. Stop.
