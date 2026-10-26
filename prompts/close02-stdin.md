# tomlq — closeout 2 of 12: standard input, byte for byte

Read `prompts/judge-v3-r2.md` (finding 2) and `prompts/close-rules.md`. If close01's Verify did not end with the 20 named
rows failing, stop and say so.

**The bug:** `read_input` in `main.lu` reads `-` with `read_line()` and stops at the first empty line, so
`printf 'a = 1\n\nb = 2\n' | ./tomlq --json -` prints `{"a":1}`. `read_line` also strips `\r` and refuses non-UTF-8, so
CRLF, a bare CR and bad UTF-8 reach the parser differently from a file.

## 1. Rows first (red)
Add these to `test.sh` part 1, right after the `I1` row (one edit):
```bash
row I2 0 '{"a":1,"b":2}' '' "printf 'a = 1\r\nb = 2\r\n' | ./tomlq --json -"
row I3 0 '2' '' "printf 'a = 1\rb = 2\n' | ./tomlq --json - >/dev/null 2>&1; echo \$?"
row I4 0 '2' '' "printf 'a = \"\xff\"\n' | ./tomlq --json - >/dev/null 2>&1; echo \$?"
```
Run `./test.sh` and paste the I1–I4 and U1 lines: I1, I3, I4 and U1 fail now (I2 already passes — CRLF without a blank
line survives `read_line`; keep it as a guard).

## 2. The fix
`-` must give the parser exactly the bytes a file with the same contents gives it, through the same decoding and the same
errors. WOLF-NOTES §… says: "Byte-exact input is `fs_open("/dev/stdin")` + `fs_read_chunk`; end of input is the `eof`
**row**." Try `fs.read_text("/dev/stdin")` first (the file path already uses `fs.read_text`); if it does not read a pipe to
its end, read chunks until the `eof` row and decode them as the file path decodes. Change only the `-` branch of
`read_input`. Commit: "Read standard input byte for byte, as a file".

## Verify (paste)
`./test.sh; echo "exit=$?"`. Expected: I1, I2, I3, I4 and U1 ok; S1v and S1i move to what the parser does from a file
(the judge measured 138/208 and 417/501 from files — paste the numbers you get, whatever they are). Every other row as
close01 left it. Stop.

**Erratum (the judge, 2026-10-26, after the session):** I3 cannot pass in this closeout. It checks that a bare CR is
refused, and the parser accepts a bare CR from a file too (`invalid/control/bare-cr` is on the judge's list); refusing it is
closeout 9, item 1. The Verify above should read: I1, I2, I4 and U1 ok; **I3 still fails** (fixed in close09). The session
that ran this prompt circled on that contradiction; `prompt-nudge03.md` released it.
