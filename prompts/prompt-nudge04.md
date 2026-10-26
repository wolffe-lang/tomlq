Stop searching for copied lists — the cause is found, and it is not in the parser.

**What is wrong.** Parsing is fine: `./tomlq '.t0.id' file` on the big files peaks at 2 MB. The blow-up is in **output**.
`emit.lu` builds JSON with `std.strbuf`, and `strbuf.push_str` is `b.s += s`: every push copies the whole output so far and
nothing is freed, so memory is the sum of every intermediate length. Measured: 40,000 one-byte pushes peak at 875 MB, 100,000
are killed at 3.4 GB (wolf-lang#298). Any `--json` or `--tagged` output past about 40 KB explodes. Your commit `68336eb` (keys
looked up in place) is right and stays; it just was not the big cost.

**The fix — two edits, nothing else:**

1. Create `sink.lu` with exactly this (it is 26 lines):
```wolf
//! A byte builder for long output. `std.strbuf`'s `push_str` is `b.s += s`, which
//! copies the whole string on every push (wolf-lang#298), so a 100,000-piece JSON
//! document needed gigabytes. A `List[byte]` grows in place.

use std.bytes

struct Sink {
    out: List[byte],
}

fn sink_new() -> Sink {
    Sink { out: List[byte]() }
}

fn sink_push(mut k: Sink, s: str) {
    let bs = s.bytes()
    var i = 0
    while i < bs.len {
        (mut k.out).push(bs[i])
        i = i + 1
    }
}

fn sink_text(k: Sink) -> str {
    bytes.to_str(k.out) else ""
}
```
2. In `emit.lu` only: delete the line `use std.strbuf`; replace every `strbuf.StrBuf` with `Sink`, every `strbuf.push_str(` with
   `sink_push(`, every `strbuf.new()` with `sink_new()`, every `strbuf.to_str(b)` with `sink_text(b)`, and the two comments
   "into a strbuf." with "into a sink.". Do it with one `sed -i ''` or `python3` command, then `grep -n strbuf emit.lu` must print
   nothing. Do not change `main.lu` (its own `strbuf` uses are small), the parser, or `test.sh`.
3. `wolf fmt *.lu` (it reflows `emit.lu`), then `wolf fmt --check *.lu`, `wolf build main.lu -o tomlq`, `wolf test .`.

**P2 changed (the judge did it, not you).** P2 is now 140,000 keys in 1,400 tables of 100. The old single 140,000-key table
measured the duplicate-key scan, which cannot pass on this toolchain (wolf's `Map` costs ~200 KB per entry, wolf-lang#972), so
it is a known limit, not this closeout's job. `prompts/close03-memory.md` carries an erratum.

**Verify (paste), then stop:**
- `./test.sh > .t.log 2>&1; echo "exit=$?"; grep -E '^(ok|FAIL) +(P1|P2|U1|J1|S1v|S1i|C[1-7])' .t.log; rm -f .t.log`
  Expected: **P1 ok** (the judge applied exactly these edits to a clone of `68336eb`: 0.45 s, 648 MB) and **P2 ok** (0.22 s, 145 MB). The C rows and S1
  are what later closeouts fix — leave them.
- Commit: `git add sink.lu emit.lu && git commit -m "Build JSON output in a byte list, not std.strbuf"`; paste `git log --oneline | head -4`
  and `git status --short`.

Then stop. Do not start closeout 4.
