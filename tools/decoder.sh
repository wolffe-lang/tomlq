#!/bin/bash
# decoder.sh — toml-test's decoder contract over tomlq: TOML on stdin, tagged JSON on stdout,
# exit 1 on a document error (tomlq exits 2 for syntax, per its spec; toml-test wants 1).
here=$(cd "$(dirname "$0")/.." && pwd)
"$here/tomlq" --tagged -
rc=$?
[ "$rc" -eq 2 ] && exit 1
exit "$rc"
