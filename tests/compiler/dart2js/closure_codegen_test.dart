// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_INVOCATION0 = r"""
main() {
  var o = null;
  o();
}
""";

const String TEST_INVOCATION1 = r"""
main() {
  var o = null;
  o(1);
}
""";

const String TEST_INVOCATION2 = r"""
main() {
  var o = null;
  o(1, 2);
}
""";

const String TEST_BAILOUT = r"""
class A {
  var x;
  foo(_) { // make sure only g has no arguments
    var f = function g() { return 499;  };
    return 499 + x + f();
  }
}

main() { new A().foo(1); }
""";

Future closureInvocation(bool minify, String prefix) {
  return Future.wait([
    compile(TEST_INVOCATION0, minify: minify, check: (String generated) {
      Expect.isTrue(generated.contains(".$prefix\$0()"));
    }),
    compile(TEST_INVOCATION1, minify: minify, check: (String generated) {
      Expect.isTrue(generated.contains(".$prefix\$1(1)"));
    }),
    compile(TEST_INVOCATION2, minify: minify, check: (String generated) {
      Expect.isTrue(generated.contains(".$prefix\$2(1,${minify ? "" : " "}2)"));
    })
  ]);
}

// Make sure that the bailout version does not introduce a second version of
// the closure.
Future closureBailout(bool minify, String prefix) {
  return compileAll(TEST_BAILOUT, minify: minify).then((generated) {
    RegExp regexp = new RegExp("$prefix\\\$0:${minify ? "" : " "}function");
    Iterator<Match> matches = regexp.allMatches(generated).iterator;
    checkNumberOfMatches(matches, 1);
  });
}

main() {
  asyncTest(() => Future.wait([
    closureInvocation(false, "call"),
    closureInvocation(true, ""),
    closureBailout(false, "call"),
    closureBailout(true, ""),
  ]));
}
