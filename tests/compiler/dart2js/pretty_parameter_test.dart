// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

#import("compiler_helper.dart");

const String FOO = r"""
void foo(var a, var b) {
}
""";


const String BAR = r"""
void bar(var eval, var $eval) {
}
""";


const String PARAMETER_AND_TEMP = r"""
void bar(var t0, var b) {
  {
    var t0 = 2;
    if (b) {
      t0 = 4;
    } else {
      t0 = 3;
    }
    print(t0);
  }
  print(t0);
}
""";

const String NO_LOCAL = r"""
foo(bar, baz) {
  if (bar) {
    baz = 2;
  } else {
    baz = 3;
  }
  return baz;
}
""";

const String MULTIPLE_PHIS_ONE_LOCAL = r"""
foo(param1, param2, param3) {
  var a = 2;
  if (param1) {
    if (param2) {
      if (param3) {
        a = 42;
      }
    }
  }
  return a;
}
""";

const String PARAMETER_INIT = r"""
int foo(var start, bool test) {
  var result = start;
  if (test) {
    result = 42;
  }
  return result;
}
""";

main() {
  String generated = compile(FOO, 'foo');
  // TODO(ngeoffray): Use 'contains' when frog supports it.
  RegExp regexp = const RegExp(r"function\(a, b\) {");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(BAR, 'bar');
  regexp = const RegExp(r"function\(eval\$, \$\$eval\) {");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(PARAMETER_AND_TEMP, 'bar');
  regexp = const RegExp(r"print\(t0\)");
  Expect.isTrue(regexp.hasMatch(generated));
  // Check that the second 't0' got another name.
  regexp = const RegExp(r"print\(t0_0\)");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(NO_LOCAL, 'foo');
  regexp = const RegExp("return baz");
  Expect.isTrue(regexp.hasMatch(generated));
  regexp = const RegExp(r"baz = 2");
  Expect.isTrue(regexp.hasMatch(generated));
  regexp = const RegExp(r"baz = 3");
  Expect.isTrue(regexp.hasMatch(generated));
  regexp = const RegExp("bar === true");
  Expect.isTrue(regexp.hasMatch(generated));

  generated = compile(MULTIPLE_PHIS_ONE_LOCAL, 'foo');
  regexp = const RegExp(r"var a = 2;");
  Expect.isTrue(regexp.hasMatch(generated));

  regexp = const RegExp(r"a = 2;");
  Iterator matches = regexp.allMatches(generated).iterator();
  Expect.isTrue(matches.hasNext());
  matches.next();
  Expect.isFalse(matches.hasNext());

  generated = compile(PARAMETER_INIT, 'foo');
  regexp = const RegExp("var result = start;");
  Expect.isTrue(regexp.hasMatch(generated));
}
