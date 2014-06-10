// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
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
      bar(1, 2);
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
    foo(1, 2);
    result = 42;
  }
  print(result);
}
""";

main() {
  asyncTest(() => Future.wait([
    compile(FOO, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains(r"function(a, b) {"));
    }),

    compile(BAR, entry: 'bar', check: (String generated) {
      Expect.isTrue(generated.contains(r"function($eval, $$eval) {"));
    }),

    compile(PARAMETER_AND_TEMP, entry: 'bar', check: (String generated) {
      Expect.isTrue(generated.contains(r"print(t00)"));
      // Check that the second 't0' got another name.
      Expect.isTrue(generated.contains(r"print(t01)"));
    }),

    compile(MULTIPLE_PHIS_ONE_LOCAL, entry: 'foo', check: (String generated) {
      Expect.isTrue(generated.contains("var a;"));
      // Check that there is only one var declaration.
      checkNumberOfMatches(new RegExp("var").allMatches(generated).iterator, 1);
    }),

    compile(NO_LOCAL, entry: 'foo', check: (String generated) {
      Expect.isFalse(generated.contains('var'));
    }),

    compile(PARAMETER_INIT, entry: 'foo', check: (String generated) {
      // Check that there is only one var declaration.
      checkNumberOfMatches(new RegExp("var").allMatches(generated).iterator, 1);
    }),
  ]));
}
