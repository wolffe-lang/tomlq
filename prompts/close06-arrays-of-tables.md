# tomlq — closeout 6 of 12: arrays of tables

Read `prompts/judge-v3-r2.md` (finding 5), README §2.1 (tables, `[[…]]`) and `prompts/close-rules.md`.

**The bug:** a second `[[s]]` is refused `key already defined` (C3a–c), so every document with an array of tables of two or
more elements fails.

## 1. Tests first (red), one per edit in `tomlq_test.lu`
`[[s]]` twice makes an array of two tables; `[[s]]` then `[s.t]` puts `t` in the LAST element; `[[a]]`, `[[a.b]]`, `[[a]]`,
`[[a.b]]` makes `a` = two tables each holding a one-element `b`; `x.y = 1` under `[[s]]` lands in the last element;
`a = [1]` then `[[a]]` is refused; `[a]` then `[[a]]` is refused; `[[a]]` then `[a]` is refused. Paste `wolf test .`
failing and `./test.sh`'s C3 lines.

## 2. The fix
`[[path]]` resolves every segment but the last as headers do — and where a segment names an array of tables, it continues
into that array's last element — then appends a new table to the array named by the last segment, creating it (marked as an
array of tables) when missing and refusing a plain array or a table. `[path]` headers and dotted keys use the same
"last element" rule. Commit: "Append to arrays of tables and resolve headers into their last element".

## 3. The cases
Run the runner with `-run 'valid/array/*' -run 'valid/table/*' -run 'valid/spec-1.0.0/array-of-tables-*'
-run valid/comment/everywhere -run valid/inline-table/key-dotted-04 -run valid/key/dotted-04` and paste the summary before
and after. The judge saw these refused for this cause: array/array-subtables, array/open-parent-table, comment/everywhere,
spec-1.0.0/array-of-tables-0, -1, table/array-empty-name, array-many, array-nest, array-table-array, names-with-values,
inline-table/key-dotted-04, key/dotted-04. Name any that still fail, with the message.

## Verify (paste)
`wolf test .`; step 3's lines; `./test.sh; echo "exit=$?"` — C3a, C3b, C3c ok. Stop.
