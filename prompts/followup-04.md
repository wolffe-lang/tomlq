# tomlq — follow-up 4 of 5: the long tail to 208/208 and 501/501

Read `prompts/judge-v3.md` and the two previous follow-ups' verifies. Same session rules. Run `./tomlq --spec
toml-test/tests --spec-verbose` once and list every remaining failure by name with its first differing path (valid) or the
rule it should have refused under (invalid) — paste that list first, before changing anything. Then fix them one at a time,
re-running only `--only <dir>` for the directory in hand; after each fix, the full `--spec` once to be sure nothing moved
backwards (a fixed case must stay fixed: add it to `tomlq_test.lu` as a small document when the fix is a rule, not a
typo). When a case cannot be made to agree without a construct wolf refuses (`cannot compile this yet`), say so by name,
keep the case failing, and move on — never weaken the comparison or skip the case silently.

**Verify (paste):** `./tomlq --spec toml-test/tests` → `valid: 208/208`, `invalid: 501/501`, or the exact short list of
what remains with its reason; `wolf test .`; `./test.sh; echo $?` → `0`. Stop.
