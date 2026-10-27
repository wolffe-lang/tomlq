> **Built by wollf.** This program was written by [wollf-v7sf3](https://huggingface.co/wolffe-lang/wollf-v7sf3),
> a 27B model trained to write wolf, driven through opencode by the prompts in `prompts/`, with a human
> reviewer judging each phase and writing the next. Every claim below is pasted from the binary; the test
> script is the reason to trust it. The README is the specification the build followed.

# tomlq

A TOML 1.0 parser and query tool in wolf, graded against the `toml-test` corpus by its own runner.

## Install

```
wolf build main.lu -o tomlq
```

Requires wolf 0.2.34 (https://github.com/wolffe-lang/wolf-lang).

## Usage

```
usage: tomlq [--json | --tagged] FILE|-
       tomlq [--raw] PATH FILE|-
       tomlq --keys PATH FILE|- | --len PATH FILE|-
       tomlq --spec DIR [--spec-verbose] [--only SUBDIR]
       tomlq --help
       tomlq --version
```

## Examples

Parse and emit plain JSON:

```
$ echo 'a = 1' | ./tomlq --json -
{"a":1}
```

Parse and emit tagged JSON (the corpus format):

```
$ echo 'a = 1' | ./tomlq --tagged -
{"a":{"type":"integer","value":"1"}}
```

Query a scalar path (prints raw):

```
$ echo 'a = 1' | ./tomlq a -
1
```

Query a table path (prints JSON):

```
$ printf '[b]\nc = 2\nd = 3\n' | ./tomlq b -
{"c":2,"d":3}
```

List keys of a table:

```
$ printf '[b]\nc = 2\nd = 3\n' | ./tomlq --keys b -
c
d
```

Count children of a table:

```
$ printf '[b]\nc = 2\nd = 3\n' | ./tomlq --len b -
2
```

Index into an array of tables:

```
$ printf '[[s]]\nn = 1\n[[s]]\nn = 2\n' | ./tomlq 's[1].n' -
2
```

A parse error (exit 2):

```
$ printf 'a = 1\na = 2\n' | ./tomlq --json -
tomlq: -:2:1: key a already defined
exit=2
```

## Exit codes

- 0: ok.
- 1: a missing PATH or a failing spec case.
- 2: a syntax or usage error.

## The grade

```
ok   S1v   valid 208/208 (toml-test ff49d109, TOML 1.0)
ok   S1i   invalid 501/501
```

The corpus is `toml-test` at commit `ff49d109861c1ad25af53f687f2aef19ab650600`. To reproduce:

```
bash tools/fetch-corpus.sh
./tomlq --spec toml-test/tests
```

## Plain JSON

Keys in document order. `inf`, `-inf`, `nan` as strings. Floats always have a `.` or an exponent. Date-times normalised: a space between date and time becomes `T`.

`--raw` prints a scalar bare (the default for a PATH query; kept for scripts). `--only SUBDIR` runs one corpus subtree. `--spec-verbose` prints each failing case's first differing path and both values.

## Known limits

TOML 1.1 is not graded. A single table with tens of thousands of keys parses in time that grows with the square of its size (the duplicate-key check scans the table; wolf 0.2.34's `Map` is too costly to index it — wolf-lang#972).

## Tests

```
wolf build main.lu -o tomlq && wolf fmt --check *.lu && wolf test .
./test.sh
```

32 rows in test.sh; 11 unit tests (`wolf test .`).

## Measured numbers

```
ok   P1    9277902 bytes, 100000 inline tables: memrun: rc=0 maxrss_mb=898 secs=0.69
ok   P2    140000 keys in 1400 tables: memrun: rc=0 maxrss_mb=108 secs=0.24
```

macOS Sonoma, Apple M-series.

## Files

| File | Description |
|------|-------------|
| `main.lu` | Entry point, CLI, spec runner, PATH queries |
| `lexer.lu` | String/number/bool/datetime tokenizers |
| `parser.lu` | TOML document parser, arena tree construction |
| `emit.lu` | JSON emitter with Sink type |
| `tree.lu` | Arena node struct and constructors |
| `sink.lu` | Byte builder for JSON output |
| `tagged_read.lu` | Tagged JSON reader and value comparator |
| `tomlq_test.lu` | Unit tests |
| `test.sh` | Test script with byte-comparing rows |
| `tools/` | Memory guard, decoder wrapper, corpus fetch |
| `prompts/` | The prompts that drove this build |
| `LICENSE` | Apache-2.0 |
| `README.md` | This document |
| `CHANGELOG.md` | Release notes |

Licensed under the Apache License 2.0 (`LICENSE`).
