Stop. Do not replace the error type with strings and do not change the parser's design again. The refusals you are chasing all come from one wrong spelling, and the lexer already has the right one.

In wolf an error is a ROW, not a struct. `-> T ! {ParseErr}` with `return ParseErr { line: …, col: …, msg: … }` is a struct literal where a row belongs: that is the "this struct-literal head" refusal, and `err.line` / `err.msg` on the caught row is the "members on this type" refusal, because a row has no fields. The compiled, working spelling is the lexer's:

```
fn parse_header(mut p: Parser) -> Header ! {ParseError(int, int, str)} {
    ...
    return ParseError(p.c.line, p.c.col, "expected [")
}
```

To pass an error up unchanged, propagate with `?` instead of catching and re-wrapping it:
```
let s = parse_string(mut p.c)?
```
(every function on the chain declares the same `! {ParseError(int, int, str)}`). To read the payload where you must, match it:
```
let v = parse_document(mut p) else |e| match e {
    ParseError(l, c, m) => {
        print("tomlq: {path}:{l}:{c}: {m}")
        return 2
    }
}
```
`"{e}"` alone prints `ParseError(3, 7, empty)`, which is fine for `--tokens`. All three forms were compiled and run on this machine's wolf before this note was written.

Do it mechanically: delete `struct ParseErr`; change every `! {ParseErr}` to `! {ParseError(int, int, str)}`; change every `return ParseErr { line: X, col: Y, msg: Z }` to `return ParseError(X, Y, Z)`; replace every `else |err| { return ParseErr { line: err.line, … } }` with a `?`; keep exactly one `match` at the top (main.lu) that prints `line:col: msg`. Then `wolf build main.lu -o tomlq`. If a refusal remains, resolve its `@A..B` with the one-liner from the previous nudge before touching anything.
