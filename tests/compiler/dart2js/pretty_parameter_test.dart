// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import 'compiler_helper.dart';

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
foo(bar, bar) {
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
      print(a);
    }
    print(a);
  }
  print(a);
}
""";

const String PARAMETER_INIT = r"""
int foo(var start, bool test) {
  var result = start;
  if (test) {
    result = 42;
  }
  print(result);
}
""";

main() {
  String generated = compile(FOO, entry: 'foo');
  Expect.isTrue(generated.contains(r"function(a, b) {"));

  generated = compile(BAR, entry: 'bar');
  Expect.isTrue(generated.contains(r"function($eval, $$eval) {"));

  generated = compile(PARAMETER_AND_TEMP, entry: 'bar');
  Expect.isTrue(generated.contains(r"print(t00)"));
  // Check that the second 't0' got another name.
  Expect.isTrue(generated.contains(r"print(t01)"));

  generated = compile(MULTIPLE_PHIS_ONE_LOCAL, entry: 'foo');
  Expect.isTrue(generated.contains("var a;"));
  // Check that there is only one var declaration.
  checkNumberOfMatches(new RegExp("var").allMatches(generated).iterator, 1);

  generated = compile(NO_LOCAL, entry: 'foo');
  Expect.isFalse(generated.contains('var'));

  generated = compile(PARAMETER_INIT, entry: 'foo');
  Expect.isTrue(generated.contains('var result = test === true ? 42 : start'));
  // Check that there is only one var declaration.
  checkNumberOfMatches(new RegExp("var").allMatches(generated).iterator, 1);
}
