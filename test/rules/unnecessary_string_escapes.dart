// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_string_escapes`

f(o){
  f("\'");// LINT
  f('\"');// LINT
  f("\"");// OK
  f('\'');// OK

  f("\'$f");// LINT
  f('\"$f');// LINT
  f("\"$f");// OK
  f('\'$f');// OK
  f("$f\'");// LINT
  f('$f\"');// LINT
  f("$f\"");// OK
  f('$f\'');// OK
  f("""\'$f""");// LINT
  f('''\"$f''');// LINT
  f("""\"$f""");// LINT
  f('''\'$f''');// LINT
  f("""$f\'""");// LINT
  f('''$f\"''');// LINT
  f("""$f\"""");// OK
  f('''$f\'''');// OK

  f('\:'); // LINT
  f('\a'); // LINT
  f('\uFFFF'); // OK
  f('\t'); // OK
  f('\n'); // OK
  f('\r'); // OK
  f('\$'); // OK
  f('\x00'); // OK
  f('\\'); // OK

  f(r"\'");// OK
  f(r'\"');// OK

  f('''_\'_'''); // LINT
  f('''_\''''); // OK otherwise parsing error
  f('''\'_'''); // LINT
  f('''_\"_'''); // LINT
  f('''_\''_'''); // LINT
  f('''_\'\'\'_'''); // OK otherwise parsing error
  f('''_'\''_'''); // OK otherwise parsing error
  f('''_\'\'\'\'\'\'_'''); // OK for >= 3 consecutive quotes

  f("""_\"_"""); // LINT
  f("""_\""""); // OK otherwise parsing error
  f("""\"_"""); // LINT
  f("""_\'_"""); // LINT
  f("""_\""_"""); // LINT
  f("""_\"\"\"_"""); // OK otherwise parsing error
  f("""_"\""_"""); // OK otherwise parsing error
  f("""_\"\"\"\"\"\"_"""); // OK for >= 3 consecutive quotes
}
