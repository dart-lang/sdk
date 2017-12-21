// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import '../compiler_helper.dart';

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

Future closureInvocation({bool useKernel, bool minify, String prefix}) async {
  await compile(TEST_INVOCATION0, useKernel: useKernel, minify: minify,
      check: (String generated) {
    Expect.isTrue(generated.contains(".$prefix\$0()"));
  });
  await compile(TEST_INVOCATION1, useKernel: useKernel, minify: minify,
      check: (String generated) {
    Expect.isTrue(generated.contains(".$prefix\$1(1)"));
  });
  await compile(TEST_INVOCATION2, useKernel: useKernel, minify: minify,
      check: (String generated) {
    Expect.isTrue(generated.contains(".$prefix\$2(1,${minify ? "" : " "}2)"));
  });
}

// Make sure that the bailout version does not introduce a second version of
// the closure.
Future closureBailout(CompileMode compileMode,
    {bool minify, String prefix}) async {
  String generated =
      await compileAll(TEST_BAILOUT, compileMode: compileMode, minify: minify);
  RegExp regexp = new RegExp("$prefix\\\$0:${minify ? "" : " "}function");
  Iterator<Match> matches = regexp.allMatches(generated).iterator;
  checkNumberOfMatches(matches, 1);
}

main() {
  runTests({bool useKernel}) async {
    await closureInvocation(
        useKernel: useKernel, minify: false, prefix: "call");
    await closureInvocation(useKernel: useKernel, minify: true, prefix: "");
    CompileMode compileMode =
        useKernel ? CompileMode.kernel : CompileMode.memory;
    await closureBailout(compileMode, minify: false, prefix: "call");
    await closureBailout(compileMode, minify: true, prefix: "");
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}
