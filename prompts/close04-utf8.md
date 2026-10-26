# tomlq — closeout 4 of 12: text — escapes decoded, multibyte kept, JSON escaped

Read `prompts/judge-v3-r2.md` (finding 6), README §2.1's string rules and `prompts/close-rules.md`.

**The bugs:** `"é\U0001F600"` decodes to `""` (C5), and every literal multibyte string decodes to `""` — the lexer
takes one byte at a time with `s.get(i..i + 1) else ""`, and a slice that splits a UTF-8 character falls to `""`. Unicode
keys therefore collide (`valid/key/case-sensitive` is refused: `"μ"` and `"Μ"` both become `""`). The emitter copies
control characters raw, so `"a\u0000b"` prints a NUL and `--json` is not JSON.

## 1. Unit tests first (red) — in `tomlq_test.lu`, one function per edit
Each parses a small document with your parser and checks the decoded value's bytes or the emitted text:
`"é"` → bytes `c3 a9`; `"\U0001F600"` → `f0 9f 98 80`; a literal `"ɑ€𐫱"` → its 9 bytes unchanged; `'é'` (literal
string) unchanged; keys `"μ"` and `"Μ"` both present; `"\uD800"` refused; `"\U00110000"` refused; `"\b\t\n\f\r\"\\"`
decoded; the emitter prints U+0001 as `\u0001`, U+001F as `\u001f`, U+007F as `\u007f`, backspace as `\b`, form feed as
`\f`, and bytes ≥ 0x80 unchanged. Multi-line basic strings: the newline right after `"""` is trimmed; a `\` at the end of a
line trims the newline and all whitespace up to the next non-whitespace character; multi-line literal strings trim the
first newline only. Paste `wolf test .` failing.

## 2. The fix
Walk the document as bytes, not one-character string slices (WOLF-NOTES on bytes: `let b = s.bytes()` copies — take the
bytes once per document and index them). Decode `\uXXXX`/`\UXXXXXXXX` to UTF-8 (1–4 bytes; refuse D800–DFFF and values
above 10FFFF with the line:col). Copy every other byte of the source unchanged. In `emit_json_string`, escape `"` `\` and
every byte below 0x20 (`\b \t \n \f \r`, else `\u00XX`) and 0x7F as `\u007f`. Commits: "Decode strings as bytes",
"Escape control characters in JSON output".

## 3. The cases
`toml-test/toml-test-runner test -toml 1.0 -decoder="$PWD/tools/decoder.sh" -run 'valid/string/*' -run 'valid/key/*'
-run valid/multibyte -run 'valid/spec-1.0.0/string-*' -run 'valid/spec-1.0.0/keys-*'` — the judge saw these fail for
this cause: string/multibyte, multibyte-escape, start-mb, escape-tricky, quoted-unicode, unicode-escape, escapes,
multiline, multiline-empty, ends-in-whitespace-escape; key/escapes, quoted-unicode, case-sensitive; multibyte;
spec-1.0.0/keys-1, string-0, string-3. Paste the runner's summary before and after.

## Verify (paste)
`wolf test .` (the count); the runner lines of step 3; `./test.sh; echo "exit=$?"` — C5 ok, J1's count lower. Stop.

**Erratum (the judge, 2026-10-26, nudge05).** C5 cannot pass here: `tomlq PATH` prints a scalar quoted, and raw scalars
are closeout 11 (finding 10). Verify C5's bytes with `--json` instead. `valid/key/escapes` stays red until closeout 5
(the quoted dotted header `["a.b"."\u00c0"]`). `emit_json_string` slices one byte at a time too, so it needs the same
whole-character walk as the lexer.
