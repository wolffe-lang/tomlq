# tomlq — follow-up 2 of 5: tables, keys and inline tables (the valid tree's 136 and the invalid tree's 82)

Read `prompts/judge-v3.md`, README §2.1 (the definition rules), §5. Same session rules as follow-up 1 (small edits, scratch
in this directory, resolve `@A..B` to its file, one construct at a time). Work from the runner: `./tomlq --spec
toml-test/tests --spec-verbose --only valid/table` names each failing case and the first differing path — fix the cause of
the first failure, rebuild, re-run, next. Directories in this order: `valid/key`, `valid/table`, `valid/inline-table`,
`valid/spec-` (the spec examples; they fall when the three before them pass), then `invalid/key`, `invalid/table`,
`invalid/inline-table`, `invalid/array`.

What the spec says, for the rules you will meet:
- A dotted key in a `[header]` creates each intermediate table implicitly; a later `[a]` header for a table that was
  only implicitly created is valid once; defining it twice is not.
- Dotted keys in key/value lines (`a.b.c = 1`) create tables too, and those tables are *closed* to later `[a.b]`
  headers in the same document (`invalid/table/append-with-dotted-keys-*`), but a later `a.b.d = 2` in the same table
  block extends them.
- `[[arr]]` appends a table to an array of tables; `[arr.sub]` after it belongs to the *last* element; a `[[x]]` whose `x`
  is a plain array or a table already is invalid; `[x]` after `[[x]]` is invalid.
- An inline table is closed after its line: `a = {b = 1}` then `a.c = 2` or `[a.c]` is invalid; an inline table inside an
  array is fine; nested inline tables are fine; a newline inside an inline table is invalid in 1.0.
- A value and a table cannot share a key; a key defined twice at any level is `already defined` with the second
  definition's line:col (C4's message shape).

Keep one function that answers "may this key be defined here" with the reason it refuses, and make every rule above a
unit test in `tomlq_test.lu` (small documents, both the accepting and the refusing case). Add tests as you fix, at most
one function per edit.

**Verify (paste):** the per-directory counts before and after (`--only` each of the eight directories); `wolf test .`;
`./test.sh; echo $?`. Stop.
