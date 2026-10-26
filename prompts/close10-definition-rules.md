# tomlq — closeout 10 of 12: invalid documents, part 2 — the definition rules

Read `prompts/judge-v3-r2.md` (finding 9), README §2.1 (tables, inline tables, "already defined") and §5 (`defined_by`),
and `prompts/close-rules.md`.

## 0. The list first
Run the runner on `-run 'invalid/*'` and paste every accepted case before changing anything.

## 1. One function decides
Write one function that answers "may this key or table be defined here?" and returns the reason when it may not; every
key/value line, dotted key, `[header]` and `[[header]]` asks it. It works from how each table came to exist (`defined_by`:
implicit by a header path, implicit by a dotted key, explicit `[header]`, inline table, array-of-tables element):
- a key defined twice in one table is refused, at any depth and in inline tables;
- an inline table is closed when its `}` is read: no later key, dotted key or header may add to it or its sub-tables;
  in TOML 1.0 an inline table has no newline inside and no trailing comma;
- a table created by dotted keys in a key/value line is closed to a later `[header]` naming it or a sub-table of it,
  but later dotted keys in the same table block may extend it;
- a table opened by `[a]` may not be opened again by `[a]`; a header path that only implicitly created `a` may be followed
  by one explicit `[a]`;
- a value and a table may not share a key; `[a]` after `[[a]]`, and `[[a]]` after `[a]` or `a = […]`, are refused.

## 2. Tests first, then the fix
A unit test per bullet, the accepting case beside the refusing one. The judge saw these accepted: inline-table/
duplicate-key-01 … -04, linebreak-01 … -04, overwrite-01, -02, -05, -06, -07, -08, -10, trailing-comma; table/
append-with-dotted-keys-01, -02, -04, -05, -07, -08, duplicate-key-01, -03, -04, -05, -09, -11, -13, redefine-02, -03,
super-twice; key/dotted-redefine-table-02; spec-1.0.0/inline-table-2-0, -3-0, table-9-0, -1. Commits as the rules land,
e.g. "Close inline tables when they end", "Close dotted-key tables to later headers".

## Verify (paste)
`wolf test .`; the runner's `invalid/*` summary before and after and every invalid case still accepted with the rule it
breaks; `./test.sh; echo "exit=$?"` — S1i `501/501` or the named remainder. Stop.
