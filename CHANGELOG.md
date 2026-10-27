## 0.1.1 (2026-10-27)

- Strings read by slice, not byte-by-byte: a 400 KB string parses in under a second.
- Named PATH failures: `tomlq: PATH: not found` (key absent) and `tomlq: PATH: not a table` (step into a scalar), exit 1.
- One operand: a second operand is refused with `tomlq: unexpected operand: NAME`, exit 2.
- A leading byte-order mark (U+FEFF) is skipped.

## 0.1.0 (2026-10-26)

A TOML 1.0 parser and query tool in wolf. Parses valid TOML, rejects invalid TOML, and supports PATH queries.

The grade: 208/208 valid cases and 501/501 invalid cases pass, as judged by toml-test's own runner at commit `ff49d109861c1ad25af53f687f2aef19ab650600`.
