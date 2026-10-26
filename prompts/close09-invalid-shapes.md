# tomlq — closeout 9 of 12: invalid documents, part 1 — control characters and line shapes

Read `prompts/judge-v3-r2.md` (finding 9), README §2.1 (comments, strings, whitespace) and `prompts/close-rules.md`.

## 0. The list first
Run `toml-test/toml-test-runner test -toml 1.0 -decoder="$PWD/tools/decoder.sh" -run 'invalid/*' 2>&1 | grep FAIL`
and paste every accepted invalid case, grouped by directory, before changing anything. This session fixes only the two
families below; the definition rules (inline tables, table and dotted-key redefinition) are close10's.

## 1. Control characters (tests first, then the fix)
Inside comments and every string form: U+0000–U+0008, U+000A–U+001F and U+007F are invalid, except tab everywhere and,
in multi-line strings, LF and CRLF. A CR not followed by LF is invalid anywhere. Each refusal names the character and its
line:col (`tomlq: FILE:L:C: control character U+007F in comment`). Unit tests: one per form (comment, basic,
literal, multi-line basic, multi-line literal) with U+0000, U+001F, U+007F, a bare CR, and tab accepted. The judge saw
control/bare-cr, comment-cr, comment-del, comment-ff, comment-lf, comment-null, comment-us, multi-del, rawmulti-del,
rawstring-del, string-del accepted. Commit: "Refuse control characters in comments and strings".

## 2. One line per key/value and per header (tests first, then the fix)
A key/value pair must end with a newline, a comment or the end of the document (`a = 1 b = 2` is invalid); a key and its
`=` are on one line (no newline inside or after a key); a `[header]` is one line and must be followed by a newline, a
comment or the end. The judge saw key/after-value, multiline-key-01 … -04, newline-01, -04, -05, -06, no-eol-01, -02, -03,
-06, -07, table/multiline-key-01, -02, newline-01, -03, -05 accepted. Unit tests per rule. Commit: "Require one line per
key/value pair and per header".

## Verify (paste)
`wolf test .`; the runner's `invalid/control/*`, `invalid/key/*` and `invalid/table/*` summaries before and after; the
list of step 0 with what remains; `./test.sh; echo "exit=$?"`. Stop.
