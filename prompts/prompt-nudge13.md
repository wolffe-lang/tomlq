# tomlq — nudge 13: closeout 11 is not done while S0 fails. "Beyond the scope of this closeout" is not an end state.

You wrote: "This requires implementing a full JSON parser and comparator, which is beyond the scope of this closeout."
The scope of closeout 11 is item 5 of `prompts/close11-the-cli.md`, which is exactly that comparator. The only acceptable
end states are `./test.sh` with **every row ok, S0 included** (`exit=0`), or a pasted case with the exact rule you dispute.
Nothing else ends this session. Delete `json_equal`, `strip_ws`, `sort_keys_json` and `sort_keys_json_inner` from `main.lu`
when the reader below replaces them.

## Why your last attempt failed, and the shape that works
Your `JsonValue` struct held `kids: List[JsonValue]` — a value nested inside itself — and wolf refused it: `cannot compile
this yet — copy of a value nested this deep`. tomlq already has the answer to that: **the arena** (`tree.lu`, `struct Node`,
`List[Node]` with `kids: List[int]` as indices). Read the tagged JSON into **the same `Node` arena** — a tagged twin has only
three shapes, and each maps to a kind you already have:
- a JSON object whose keys are exactly `type` and `value` → a **leaf** `Node`: `kind` from the type name (`string` 2,
  `integer` 3, `float` 4, `bool` 5, `datetime` 6, `datetime-local` 7, `date-local` 8, `time-local` 9) and the value's
  **text** kept in `s` (never converted here; `b`, `i`, `f` stay zero);
- any other JSON object → a **table** `Node` (kind 0): each key into `keys`, each value's index into `kids`;
- a JSON array → an **array** `Node` (kind 1): each element's index into `kids`.
Also `E0410`: a cursor that moves is `var`, never `let`.

## 1. The reader — a new file `tagged_read.lu` (≤ 60 lines per edit; build after each)
```
/// Read a toml-test tagged JSON document into the arena; returns the root's index.
fn read_tagged(mut arena: List[Node], text: str) -> int ! {ParseError(int, int, str)}
```
with a `var pos: int` cursor over `text` and these helpers, each small: `skip_ws`, `read_string` (JSON string: `\"` `\\` `\/`
`\b` `\f` `\n` `\r` `\t` `\uXXXX` including surrogate pairs — reuse `lexer.lu`'s escape code if it is callable, else write
the 20 lines), `read_value` (dispatch on `{`, `[`, `"`, `t`/`f`/`n`, digits; a twin never has bare numbers outside
`value`, but accept them as text), `read_array`, `read_object`. `read_object` collects its pairs into two lists; if the keys
are exactly `type` and `value` (either order), it makes the leaf; otherwise the table. Unknown type name → ParseError.

## 2. Compare as values — `fn tree_equal(a: List[Node], ia: int, b: List[Node], ib: int) -> bool` in `tagged_read.lu`
- kinds differ → false.
- table: `keys.len` equal, and for every key in `a` the same key exists in `b` (order free: look it up by name) and
  `tree_equal` on the two kids;
- array: same `kids.len`, `tree_equal` element by element in order;
- leaves, by kind: string → `a.s == b.s`; integer → compare as numbers (`i64` parse of both texts; a leading `+` allowed);
  float → `decimal.parse_float` of both, equal when both are `nan`, else `==`; the four date-time kinds → equal after
  normalising: a `t`/space between date and time becomes `T`, a trailing `z` becomes `Z`; bool → the texts.
A failing case's first differing **path** (`a.b[2].c`) and both texts, for `--spec-verbose`: add
`fn tree_diff(a, ia, b, ib, path: str) -> str` returning `""` when equal, else `"<path>: <a text> != <b text>"`; `tree_equal`
is `tree_diff(...) == ""`.

## 3. Wire it in `spec_run` (main.lu, where `json_equal(actual, expected)` is called)
Read **both** sides with `read_tagged` — your own `--tagged` output (`actual`) and the twin (`expected`) — into two fresh
arenas, then `tree_diff`. If `read_tagged` fails on the twin, count the case as failed and name it under `--spec-verbose`.
Unit tests (`tomlq_test.lu`): the leaf form; a table with keys in two orders equal; `1.0` vs `1` float texts equal when
both are floats; `1979-05-27t07:32:00z` equals `1979-05-27T07:32:00Z`; `nan` equals `nan`; an array order mismatch unequal.

## 4. Verify (paste all; stop only at S0 ok and exit=0)
`wolf build main.lu -o tomlq && wolf fmt --check *.lu && wolf test .`; `./tomlq --spec toml-test/tests | tail -n 2` →
`valid: 208/208 passed` and `invalid: 501/501 passed`; `./test.sh; echo "exit=$?"` → every row ok, `exit=0`. Commits:
"Read tagged JSON into the arena", "Compare spec cases as values". If a valid case still differs, paste its name, its
twin's text, your `--tagged` text and the first differing path — that, and only that, is the other way to stop.
