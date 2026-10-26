# tomlq — follow-up 5 of 5: release readiness

Read `prompts/judge-v3.md`. Same session rules. The grade must already be green (follow-up 4's verify); if it is not, stop
and say so. This session writes no parser code.

1. **The tool's README** replaces the spec copy (keep the spec at `../../README.md` where it lives): what tomlq is in two
   sentences; install (`wolf build main.lu -o tomlq`, the wolf version it builds with); the usage block pasted from
   `./tomlq --help`; the forms with one example each (`--json`, `--tagged`, PATH, `--keys`, `--len`, `--raw`, `--spec`);
   the grade (the two counts and the corpus commit); the plain-JSON notes (`inf`/`nan` as strings, documented); known
   limits (TOML 1.1 cases not graded; anything from follow-up 4's remaining list); the test commands. Plain prose, no
   claims the counts do not back.
2. **`--version`** → `tomlq 0.1.0 (built with wolf <version>)`, exit 0; a `VERSION` constant in `main.lu`.
3. **LICENSE**: Apache-2.0, the full text verbatim (download it, do not retype it: `curl -sL
   https://www.apache.org/licenses/LICENSE-2.0.txt > LICENSE`; `sha256sum LICENSE` must print
   `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`); the copyright line in README.
4. **CHANGELOG.md**: `## 0.1.0 (date)` with what the tool does, the grade, and the corpus commit.
5. **A `.gitignore`** (`tomlq`, `*.dSYM`, `toml-test/`, scratch files), and the final tree listed in your message with
   `ls` — the maintainer creates the repository and pushes; you do not run `git init` or push anything.

**Verify (paste):** `./tomlq --version`; `sha256sum LICENSE`; `./test.sh; echo $?` → `0`; `wolf test .`; `ls`. Stop.
