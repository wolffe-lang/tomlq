Stop. You have run `escapes.toml` and read `code_point_to_str` about twenty times without changing a file. Here is what is
actually wrong, then the exact edits. Do them in order, one small edit at a time.

**What the loop missed.** `escapes.toml` is all ASCII, and its escapes already decode: `\b` comes out as the byte 08. The
output only *looks* wrong because the emitter copies control bytes raw instead of writing `\b`, `\f`, `\u001f`, `\u007f`.
The real bugs are elsewhere:
1. **Every non-ASCII character becomes `""`.** `cursor_peek` and `cursor_advance` in `lexer.lu` take one byte at a time
   (`c.s.get(c.pos..c.pos + 1)`). A slice that splits a UTF-8 character is refused and falls to `""`. So `"é"` → `""`,
   `'é'` → `""`, and the keys `"μ"` and `"Μ"` collide ("key already defined").
2. **`code_point_to_str` returns `""` for anything past ASCII**, so `"é"` and `"\U0001F600"` decode to `""`.
3. **`emit_json_string` (emit.lu) has the same one-byte slice**, so it also drops multibyte characters, and it never
   escapes control bytes.
4. **A line-ending backslash in `"""` strings** trims only one newline. TOML trims the newline and *every* space, tab and
   newline after it, up to the next other character.

**Erratum (the judge's mistake, not yours):** C5 cannot pass in this closeout. `./tomlq .x -` prints a scalar *quoted*
(`"é😀"`), and C5 wants it raw; raw scalars are closeout 11 (judge finding 10, C2a). Check C5's bytes with `--json`
instead (step 5). `valid/key/escapes` also stays red until closeout 5: it fails on the quoted dotted header
`["a.b"."À"]`, not on an escape.

## Step 1 — the tests, red
Append the judge's tests: `cat ~/lanes/orch-tomlq/judge-1026/nudge05/tests04.lu >> tomlq_test.lu`, then
`wolf fmt tomlq_test.lu` and `wolf test .`. Expect **3 FAILED** (`test_strings_decode_as_utf8`,
`test_json_escapes_control_characters`, `test_line_ending_backslash_trims_whitespace`) and 2 ok. Commit:
`git add tomlq_test.lu && git commit -m "tests: strings as UTF-8, JSON control escapes, the line-ending backslash (red)"`.

## Step 2 — lexer.lu, whole characters
(a) Line 3: replace `use std.strbuf` with `use std.bytes` (after (c), nothing in lexer.lu uses strbuf).
(b) Insert this function just above `fn cursor_advance`:
```wolf
/// The whole UTF-8 character starting at byte `pos` of `s`, or "" at the end.
/// A slice that splits a character is refused, so try one to four bytes.
fn char_at(s: str, pos: int) -> str {
    var n = 1
    while n <= 4 && pos + n <= s.len {
        let ch = s.get(pos..pos + n) else ""
        if ch != "" {
            return ch
        }
        n = n + 1
    }
    ""
}
```
In `cursor_advance`, replace the two lines
`let ch = c.s.get(c.pos..c.pos + 1) else ""` and `c.pos = c.pos + 1` with
```wolf
    let ch = char_at(c.s, c.pos)
    c.pos = c.pos + (if ch.len > 0 then ch.len else 1)
```
In `cursor_peek`, replace its last line `c.s.get(c.pos..c.pos + 1) else ""` with `char_at(c.s, c.pos)`.
(c) Replace the whole `code_point_to_str` function with:
```wolf
/// Encode a Unicode code point as UTF-8 (1 to 4 bytes).
fn code_point_to_str(cp: int) -> str {
    var out = List[byte]()
    if cp < 0x80 {
        (mut out).push(cp as byte)
    } else if cp < 0x800 {
        (mut out).push((0xC0 + cp / 64) as byte)
        (mut out).push((0x80 + cp % 64) as byte)
    } else if cp < 0x10000 {
        (mut out).push((0xE0 + cp / 4096) as byte)
        (mut out).push((0x80 + cp / 64 % 64) as byte)
        (mut out).push((0x80 + cp % 64) as byte)
    } else {
        (mut out).push((0xF0 + cp / 262144) as byte)
        (mut out).push((0x80 + cp / 4096 % 64) as byte)
        (mut out).push((0x80 + cp / 64 % 64) as byte)
        (mut out).push((0x80 + cp % 64) as byte)
    }
    bytes.to_str(out) else ""
}
```
`wolf fmt *.lu && wolf build main.lu -o tomlq`. Commit: `git add lexer.lu && git commit -m "Decode strings as bytes"`.

## Step 3 — lexer.lu, the line-ending backslash
In `parse_multiline_basic_string` only:
(a) Replace the two branches that start `} else if esc == "\n" || esc == "\r" {` and `} else if esc == " " || esc == "\t" {`
(everything from the first of them down to, not including, the final `} else {` that returns `invalid escape \\{esc}`)
with this one branch:
```wolf
            } else if esc == "\n" || esc == "\r" || esc == " " || esc == "\t" {
                // A line-ending backslash: only spaces and tabs may follow it on
                // its line, and it trims that newline and every space, tab and
                // newline after it, up to the next other character.
                var newline = esc == "\n" || esc == "\r"
                while !cursor_at_end(c) {
                    let ws = cursor_peek(c)
                    if ws == "\n" || ws == "\r" {
                        newline = true
                        cursor_advance(mut c)
                    } else if ws == " " || ws == "\t" {
                        cursor_advance(mut c)
                    } else {
                        break
                    }
                }
                if !newline {
                    return ParseError(c.line, c.col, "invalid escape \\{esc}")
                }
```
(b) Add the line `after_open = false` as the first line inside `if ch == "\\" {` and as the first line inside
`} else if ch == "\"" {` (an escape or a quote ends the "newline right after the opening quotes" window).
`wolf fmt *.lu && wolf build main.lu -o tomlq`. Commit: `git add lexer.lu && git commit -m "Trim a line-ending backslash through blank lines"`.

## Step 4 — emit.lu, the JSON escapes
In `emit_json_string`: replace `let ch = s.get(i..i + 1) else ""` with
```wolf
        let ch = char_at(s, i)
        if ch == "" {
            i = i + 1
        } else {
            i = i + ch.len
        }
```
delete the `i = i + 1` line at the bottom of the loop, and put these three branches just before its final `} else {`:
```wolf
        } else if ch == "\x08" {
            sink_push(mut b, "\\b")
        } else if ch == "\x0C" {
            sink_push(mut b, "\\f")
        } else if ch.len == 1 && (ch < " " || ch == "\x7F") {
            sink_push(mut b, json_control(ch))
```
Add this function after `emit_json_string`:
```wolf
/// `\u00XX` for a control character (one byte below 0x20, or 0x7F).
fn json_control(ch: str) -> str {
    let v = ch.bytes()[0] as int
    let hex = "0123456789abcdef"
    let hi = hex.get(v / 16..v / 16 + 1) else "0"
    let lo = hex.get(v % 16..v % 16 + 1) else "0"
    "\\u00" + hi + lo
}
```
`wolf fmt *.lu && wolf build main.lu -o tomlq && wolf test .` — **5 passed**. Commit:
`git add emit.lu && git commit -m "Escape control characters in JSON output"`.

## Step 5 — verify (paste), then stop
- `wolf test .` → 5 passed.
- `printf 'x = "\\u00e9\\U0001F600"\n' | ./tomlq --json - | od -An -tx1` → `7b 22 78 22 3a 22 c3 a9 f0 9f 98 80 22 7d 0a`.
- The runner line from closeout 4 step 3 → the judge measured **valid 36 passed, 32 failed** before and **52 passed,
  16 failed** after; the 16 left are all keys closeout 5 fixes (key/dotted-*, numeric-*, like-date, start, escapes;
  spec-1.0.0/keys-3 to keys-7).
- `./test.sh > .t.log 2>&1; grep -E '^(ok|FAIL) +(S1v|J1|U1|P1|P2|C5)' .t.log; rm -f .t.log` → the judge saw S1v
  155/208 (was 138), J1 24 cases (was 31), U1 13 (was 15), P1 and P2 ok, C5 FAIL (closeout 11).
- `git log --oneline | head -5` and `git status --short`.

If anything differs from these numbers, paste it and stop; do not hunt. Do not start closeout 5.
