// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// Test that parameters keep their names in the output.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

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
    var f = () { return 499;  };
    return 499 + x + f();
  }
}

main() { new A().foo(1); }
""";

Future closureInvocation({bool minify, String prefix}) async {
  await compile(TEST_INVOCATION0, minify: minify, check: (String generated) {
    Expect.isTrue(generated.contains(".$prefix\$0()"));
  });
  await compile(TEST_INVOCATION1, minify: minify, check: (String generated) {
    Expect.isTrue(generated.contains(".$prefix\$1(1)"));
  });
  await compile(TEST_INVOCATION2, minify: minify, check: (String generated) {
    Expect.isTrue(generated.contains(".$prefix\$2(1,${minify ? "" : " "}2)"));
  });
}

// Make sure that the bailout version does not introduce a second version of
// the closure.
Future closureBailout({bool minify, String prefix}) async {
  String generated = await compileAll(TEST_BAILOUT, minify: minify);
  RegExp regexp = new RegExp("$prefix\\\$0:${minify ? "" : " "}function");
  Iterator<Match> matches = regexp.allMatches(generated).iterator;
  checkNumberOfMatches(matches, 1);
}

main() {
  runTests() async {
    await closureInvocation(minify: false, prefix: "call");
    await closureInvocation(minify: true, prefix: "");
    await closureBailout(minify: false, prefix: "call");
    await closureBailout(minify: true, prefix: "");
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
