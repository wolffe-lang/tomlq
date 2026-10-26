#!/bin/bash
# test.sh — every row prints ok or FAIL with what it saw; exit 0 only when all pass.
cd "$(dirname "$0")"
fails=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; shift; for l in "$@"; do echo "       $l"; done; fails=$((fails + 1)); }
# row NAME RC STDOUT STDERR CMD — runs CMD with bash -c; compares stdout, the first stderr line, rc.
row() {
  local name=$1 want_rc=$2 want_out=$3 want_err=$4 cmd=$5 out err rc
  out=$(bash -c "$cmd" 2>.row-err); rc=$?
  err=$(head -n 1 .row-err); rm -f .row-err
  if [ "$rc" = "$want_rc" ] && [ "$out" = "$want_out" ] && [ "$err" = "$want_err" ]; then pass "$name"
  else fail "$name" "cmd:    $cmd" "want:   rc=$want_rc out=[$want_out] err=[$want_err]" \
    "got:    rc=$rc out=[$out] err=[$err]"; fi
}
step() { local name=$1; shift; if "$@" > .step-out 2>&1; then pass "$name"; else fail "$name" "$(tail -n 5 .step-out)"; fi; rm -f .step-out; }

step "fmt   wolf fmt --check *.lu" wolf fmt --check *.lu
step "build wolf build main.lu -o tomlq" wolf build main.lu -o tomlq
[ -x ./tomlq ] || { echo "no binary; stopping"; exit 1; }
step "unit  wolf test ." wolf test .
row C1 0 '{"a":{"b":1},"c":{"d":"x"}}' '' "printf 'a.b = 1\n[c]\nd = \"x\"\n' | ./tomlq --json -"
printf 'a.b = 1\n[c]\nd = "x"\n' > .c2.toml
row C2a 0 'x' '' "./tomlq .c.d .c2.toml"
row C2b 0 '1' '' "./tomlq .a.b .c2.toml"
row C2c 1 '' '' "./tomlq .nope .c2.toml"
printf '[[s]]\nh="a"\n[[s]]\nh="b"\n' > .c3.toml
row C3a 0 'b' '' "./tomlq '.s[1].h' .c3.toml"
row C3b 0 '2' '' "./tomlq --len .s .c3.toml"
row C3c 0 'h' '' "./tomlq --keys '.s[0]' .c3.toml"
row C4 2 '' 'tomlq: -:2:1: key a already defined' "printf 'a = 1\na = 2\n' | ./tomlq --json -"
row C5 0 "$(printf '\xc3\xa9\xf0\x9f\x98\x80')" '' "printf 'x = \"\\\\u00e9\\\\U0001F600\"\n' | ./tomlq .x -"
row C6 0 '{"t":{"type":"datetime","value":"1979-05-27T07:32:00.999Z"}}' '' "printf 't = 1979-05-27 07:32:00.999Z\n' | ./tomlq --tagged -"
row C7a 0 '{"f":100.0,"g":"-inf"}' '' "printf 'f = 1e2\ng = -inf\n' | ./tomlq --json -"
row C7b 0 '{"f":{"type":"float","value":"100"},"g":{"type":"float","value":"-inf"}}' '' "printf 'f = 1e2\ng = -inf\n' | ./tomlq --tagged -"
row I1 0 '{"a":1,"b":2}' '' "printf 'a = 1\n\nb = 2\n' | ./tomlq --json -"
row I2 0 '{"a":1,"b":2}' '' "printf 'a = 1\r\nb = 2\r\n' | ./tomlq --json -"
row I3 0 '2' '' "printf 'a = 1\rb = 2\n' | ./tomlq --json - >/dev/null 2>&1; echo \$?"
row I4 0 '2' '' "printf 'a = \"\xff\"\n' | ./tomlq --json - >/dev/null 2>&1; echo \$?"
row E1 2 '' 'usage: tomlq [--json | --tagged] FILE|-' "./tomlq"
row E2 2 '' 'tomlq: unknown option: --bogus' "./tomlq --bogus x"
row E3 2 '' 'tomlq: /nonexistent: no such file' "./tomlq --json /nonexistent"
row V1 0 'tomlq 0.1.0 (built with wolf 0.2.34)' '' "./tomlq --version"
rm -f .c2.toml .c3.toml

# test.sh, part 2 — the corpus (toml-test's own runner is the grader), stdin = file, JSON validity, P1.
if bash tools/fetch-corpus.sh > .fetch-out 2>&1; then
  grade=$(toml-test/toml-test-runner test -toml 1.0 -decoder="$PWD/tools/decoder.sh" -timeout 5s -parallel 4 2>&1 | tail -n 4)
  v=$(echo "$grade" | awk '/valid tests:/ && !/invalid/ {print $3"/"$3+$5}')
  i=$(echo "$grade" | awk '/invalid tests:/ {print $3"/"$3+$5}')
  [ "$v" = "208/208" ] && pass "S1v   valid $v (toml-test ff49d109, TOML 1.0)" || fail "S1v   valid $v, want 208/208" "run: toml-test/toml-test-runner test -toml 1.0 -decoder=\$PWD/tools/decoder.sh"
  [ "$i" = "501/501" ] && pass "S1i   invalid $i" || fail "S1i   invalid $i, want 501/501"
  bad=""; nbad=0; badj=""; nj=0
  for f in $(grep '^valid/.*\.toml$' toml-test/tests/files-toml-1.0.0); do
    p=toml-test/tests/$f
    a=$(./tomlq --tagged "$p" 2>&1); b=$(./tomlq --tagged - < "$p" 2>&1)
    [ "$a" = "$b" ] || { nbad=$((nbad + 1)); [ $nbad -le 5 ] && bad="$bad $f"; }
    ./tomlq --json "$p" 2>/dev/null | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null || { nj=$((nj + 1)); [ $nj -le 5 ] && badj="$badj $f"; }
  done
  [ $nbad -eq 0 ] && pass "U1    stdin and file agree on all 208 valid cases" || fail "U1    stdin differs from file on $nbad cases" "first:$bad"
  [ $nj -eq 0 ] && pass "J1    --json is JSON on all 208 valid cases" || fail "J1    --json not JSON (or refused) on $nj cases" "first:$badj"
else
  fail "S1    corpus fetch or runner build failed" "$(tail -n 3 .fetch-out)"
fi
rm -f .fetch-out
python3 -c "
with open('.p1.toml', 'w') as f:
    f.write('items = [\n')
    for i in range(100000):
        f.write('  {id = %d, name = \"item-%06d\", price = %d.%02d, tags = [\"red\", \"green\"], note = \"row\"},\n' % (i, i, i % 1000, i % 100))
    f.write(']\n')
"
p1=$(bash tools/memrun.sh 2048 20 ./tomlq --json .p1.toml 2>&1 > .p1.json | tail -n 1)
n=$(python3 -c 'import json; print(len(json.load(open(".p1.json"))["items"]))' 2>/dev/null)
s=$(echo "$p1" | sed -n 's/.*secs=\([0-9.]*\).*/\1/p')
if echo "$p1" | grep -q 'rc=0 ' && [ "$n" = 100000 ] && python3 -c "import sys; sys.exit(0 if float('$s') < 2 else 1)"; then pass "P1    $(ls -l .p1.toml | awk '{print $5}') bytes, 100000 inline tables: $p1"
else fail "P1    want rc=0, 100000 items, secs < 2, under 2048 MB" "got: $p1 items=$n"; fi
rm -f .p1.toml .p1.json
echo
[ $fails -eq 0 ] && { echo "All rows passed."; exit 0; }
echo "$fails rows failed."; exit 1
