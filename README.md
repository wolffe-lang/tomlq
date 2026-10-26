# tomlq

A TOML 1.0 parser and query tool written in wolf. Parses TOML documents into an
arena-based value tree and emits plain JSON or corpus-style tagged JSON. Grades
against the `toml-test` corpus.

## Install

Requires wolf. Build with:

```
wolf build main.lu -o tomlq
```

## Usage

```
usage: tomlq [--json | --tagged] FILE
       tomlq [--raw] PATH FILE
       tomlq --keys PATH FILE | --len PATH FILE
       tomlq --spec DIR [--spec-verbose] [--only SUBDIR]
       tomlq --help
       tomlq --version
```

### Forms

- `--json FILE` — print the document as plain JSON.
- `--tagged FILE` — print the document as corpus-style tagged JSON
  (`{"type":..., "value":...}` leaves).
- `PATH FILE` — print JSON of the node at PATH (dot-separated, `[N]` indexes).
- `--keys PATH FILE` — print the keys of the node at PATH, one per line.
- `--len PATH FILE` — print the length of the node at PATH.
- `--raw PATH FILE` — print the raw value of the node at PATH.
- `--spec DIR` — run the corpus in DIR against the parser and print the grade.
- `-` as FILE reads stdin.

### Plain JSON notes

- `inf`, `-inf`, and `nan` are emitted as strings (wolf has no `f64` literals).
- Datetimes are zero-padded and normalized (`T` separator, `Z` offset).

### Grade

```
valid: 93/208 passed
invalid: 417/501 passed
```

Corpus: `toml-test` at commit `ff49d109861c1ad25af53f687f2aef19ab650600`.

### Known limits

- TOML 1.1 cases are not graded (the 1.0 list is used).
- Key ordering in JSON output is not sorted (comparison uses `strip_ws`).
- Some invalid cases are accepted that should be rejected (control characters,
  inline table rules, key redefinition in certain contexts).

## Test

```
wolf build main.lu -o tomlq
wolf test .
./test.sh
```

## License

Apache-2.0. Copyright 2026 tomlq authors.
