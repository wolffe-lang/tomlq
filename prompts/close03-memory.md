# tomlq — closeout 3 of 12: memory that grows with the input, not with its square

Read `prompts/judge-v3-r2.md` (finding 3) and `prompts/close-rules.md`. Run every probe in this session through
`bash tools/memrun.sh` exactly as written below — a run once reached 37 GB on this Mac.

## 1. Measure (paste the three memrun lines)
```bash
for n in 1000 2000 4000; do
  python3 -c "
with open('.p2.toml','w') as f:
    f.write('items = [\n')
    for i in range($n): f.write('  {id = %d, name = \"item-%d\"},\n' % (i, i))
    f.write(']\n')"
  bash tools/memrun.sh 4096 30 ./tomlq --json .p2.toml > /dev/null
done; rm -f .p2.toml
```
The judge saw 438 MB at 1,000 rows and 11.6 GB at 5,000: doubling the rows multiplies memory by about four.

## 2. A second row (red)
Append to `test.sh` part 2, after the P1 block (one edit) — the round-1 judge measured this file at 0.35 s:
```bash
python3 -c "
with open('.p2.toml', 'w') as f:
    for i in range(140000): f.write('key%d = %d\n' % (i, i))
"
p2=$(bash tools/memrun.sh 2048 20 ./tomlq --json .p2.toml 2>&1 > /dev/null | tail -n 1)
s=$(echo "$p2" | sed -n 's/.*secs=\([0-9.]*\).*/\1/p')
if echo "$p2" | grep -q 'rc=0 ' && python3 -c "import sys; sys.exit(0 if float('$s') < 2 else 1)"; then pass "P2    140000 flat keys: $p2"
else fail "P2    want rc=0, secs < 2, under 2048 MB" "got: $p2"; fi
rm -f .p2.toml
```
(Put it before the final `echo` and the exit lines.) Run `./test.sh` and paste P1 and P2 (failing).

## 3. The fix
`add_key_checked` and `find_child` in `parser.lu` call `node_keys(p.arena, parent)`, which copies the table's whole key
list, on every insertion — so a table of n keys costs n copies of up to n strings. Read the keys in place instead (index
`p.arena[parent].keys` inside the loop rather than binding a copy), and look for the same pattern anywhere a loop binds a
`List` out of the arena (`node_kids`, `node_keys` in `parser.lu`, `emit.lu`, `main.lu`). Do not change the tree's shape or
the parser's results. Re-run step 1 after each change and paste the lines. Commit: "Look up keys in place instead of
copying the key list".

## Verify (paste)
Step 1's three lines after the fix (memory should roughly double, not quadruple, per doubling); `./test.sh; echo
"exit=$?"` with P1 and P2 ok and their memrun lines. Every other row as close02 left it. Stop.

**Erratum (the judge, 2026-10-26, after the session's first fix):** two things the prompt got wrong.
(1) The copies of the key list were real but not the main cost: `std.strbuf.push_str` is `b.s += s`, which copies the whole
output on every push and frees nothing (wolf-lang#298), so any `--json`/`--tagged` output past ~40 KB took gigabytes. The fix is
the byte-list sink in `prompt-nudge04.md`.
(2) P2 as first written (140,000 keys in ONE table) measures the duplicate-key scan, which is linear per insert; it cannot pass in
2 s, and wolf 0.2.34's `Map` cannot index it (10,000 string-key inserts peak at 2.1 GB; wolf-lang#972). The judge changed P2 to 140,000 keys in
1,400 tables of 100; the single huge table is a known limit for the README (close12).

