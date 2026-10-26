Stop redesigning the parser around `Map`; nothing in the message says `Map` is the problem. Read the refusal the way it is written.

`wolf build: cannot compile this yet — <construct> @A..B` is the conservatism ledger: your program is legal, the native backend refuses one construct, and `@A..B` is a BYTE range into one of the files of the directory module. `wolf build main.lu` compiles every `.lu` in the directory as one module, so the range is usually NOT in the file you named on the command line (that is why `@6743..6769` never moved when you rebuilt `test_char.lu`: it is in `lexer.lu`). Resolve it before you change anything:

```
python3 -c "
import glob
for f in sorted(glob.glob('*.lu')):
    b=open(f,'rb').read()
    if 234<=len(b): print(f, 'line', b[:224].count(b'\n')+1, b[224:234])"
```

Run that for each `@A..B` you see (change 224/234). The file whose bytes read as code at that range is the one; the others print noise. Then fix the construct, not the design:

- `methods on builtin types (the std surface)`: a method called on a builtin receiver (`str`, `int`, `char`, `bool`) that this wolf version's std does not provide on the compiled tiers (for example `s.get(a..b)`, `s.starts_with(..)`, `cp as char` feeding a builtin method). Spell it without the method: slice with `s[a..b]` on code-point boundaries, compare bytes with `s[i..i+1] == "'"`, build strings with `strbuf`, or loop. Check with a three-line probe file before touching the real one.
- `members on this type (the std surface)`: a field read (`x.name`) on a value whose type is not a struct — most often an error-union or option that has not been unwrapped yet (`err.msg` inside an `else |err|`, or a `!` result used before `else`), or a tuple. Unwrap first (`else |e| { … }`, `match`), or annotate the variable's type.
- `this struct-literal head`: the name before `{` is not a struct the resolver can see here — a typo, a struct defined in another file of the module that this file never names, or an enum variant written with struct syntax (`ParseError { … }` where `ParseError(line, col, msg)` is a tuple variant).

Do one refusal at a time: resolve the range, print the ten lines around it, change that one construct, rebuild, and only then move to the next. Keep `Map[str, int]` in `Parser`; it was never the message.
