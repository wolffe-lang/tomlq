#!/bin/bash
set -e

echo "=== wolf fmt --check ==="
wolf fmt --check *.lu
echo "PASS"

echo "=== wolf build ==="
wolf build main.lu -o tomlq
echo "PASS"

echo "=== --help exits 0 ==="
./tomlq --help > /dev/null
echo "PASS"

echo "=== --json on valid file ==="
./tomlq --json toml-test/tests/valid/array/nospaces.toml > /dev/null
echo "PASS"

echo "=== --tagged on valid file ==="
./tomlq --tagged toml-test/tests/valid/array/nospaces.toml > /dev/null
echo "PASS"

echo "=== --keys on valid file ==="
./tomlq --keys "" toml-test/tests/valid/example.toml > /dev/null
echo "PASS"

echo "=== --len on valid file ==="
./tomlq --len "numtheory.perfection" toml-test/tests/valid/example.toml > /dev/null
echo "PASS"

echo "=== --raw on valid file ==="
./tomlq --raw "best-day-ever" toml-test/tests/valid/example.toml > /dev/null
echo "PASS"

echo "=== PATH query on valid file ==="
./tomlq "best-day-ever" toml-test/tests/valid/example.toml > /dev/null
echo "PASS"

echo "=== stdin ==="
printf 'a = 1\n' | ./tomlq --json - > /dev/null
echo "PASS"

echo "=== --spec ==="
timeout 120 ./tomlq --spec toml-test/tests 2>&1 | tail -2
echo "PASS"

echo ""
echo "All tests passed."
exit 0
