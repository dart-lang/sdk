// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=-DUSE_CPS_IR=true

// Test that the CPS IR code generator is able to compile the provided
// example programs.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/apiimpl.dart'
       show Compiler;
import 'memory_compiler.dart';

const String TEST_MAIN_FILE = 'test.dart';

/// The list of tests to run.
const List<String> RAW_TESTS = const [
  """
foo(a) {
  return a;
}
main() {
  var a = 10;
  var b = 1;
  var t;
  t = a;
  a = b;
  b = t;
  print(a);
  print(b);
  print(b);
  print(foo(a));
}
  """,
  """
foo() { return 42; }
main() { return foo(); }
  """,
  "main() {}",
  "main() { return 42; }",
];

String formatTest(Map test) {
  return test[TEST_MAIN_FILE];
}

main() {
  Expect.isTrue(const bool.fromEnvironment("USE_CPS_IR"));

  Iterable<Map> tests =
    RAW_TESTS.map((String text) => {TEST_MAIN_FILE: text});

  for (Map test in tests) {
    asyncTest(() {
      Compiler compiler = compilerFor(test);
      Uri uri = Uri.parse('memory:$TEST_MAIN_FILE');
      return compiler.run(uri).then((_) {
        Expect.isNotNull(compiler.assembledCode);
      }).catchError((e) {
        Expect.fail('The following test failed to compile:\n'
                    '${formatTest(test)}');
      });
    });
  }
}
