#!/bin/bash
# fetch-corpus.sh — put toml-test at the pinned commit in ./toml-test and build its runner.
set -e
pin=ff49d109861c1ad25af53f687f2aef19ab650600
if [ ! -d toml-test/.git ]; then
  git init -q toml-test
  git -C toml-test fetch -q --depth 1 https://github.com/toml-lang/toml-test "$pin"
  git -C toml-test checkout -q FETCH_HEAD
fi
have=$(git -C toml-test rev-parse HEAD)
[ "$have" = "$pin" ] || { echo "toml-test is at $have, want $pin" >&2; exit 1; }
[ -x toml-test/toml-test-runner ] || (cd toml-test && go build -o toml-test-runner ./cmd/toml-test)
