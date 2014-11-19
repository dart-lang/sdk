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
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/common.dart' show Element;


const String TEST_MAIN_FILE = 'test.dart';

class TestEntry {
  final String source;
  final String expectation;
  const TestEntry(this.source, [this.expectation]);
}

/// The list of tests to run.
const List<TestEntry> tests = const [
  const TestEntry(
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
function() {
  var a, b;
  a = 10;
  b = 1;
  P.print(b);
  P.print(a);
  P.print(a);
  P.print(V.foo(b));
  return null;
}"""),
  const TestEntry(
  """
foo() { return 42; }
main() { return foo(); }
  """,
  """function() {
  return V.foo();
}"""),
  const TestEntry("main() {}"),
  const TestEntry("main() { return 42; }"),
];

String formatTest(Map test) {
  return test[TEST_MAIN_FILE];
}

String getCodeForMain(Compiler compiler) {
  Element mainFunction = compiler.mainFunction;
  js.Node ast = compiler.enqueuer.codegen.generatedCode[mainFunction];
  return js.prettyPrint(ast, compiler).getText();
}

main() {
  Expect.isTrue(const bool.fromEnvironment("USE_CPS_IR"));

  for (TestEntry test in tests) {
    Map files = {TEST_MAIN_FILE: test.source};
    asyncTest(() {
      Compiler compiler = compilerFor(files);
      Uri uri = Uri.parse('memory:$TEST_MAIN_FILE');
      return compiler.run(uri).then((_) {
        Expect.isNotNull(compiler.assembledCode);
        String expectation = test.expectation;
        if (expectation != null) {
          Expect.equals(test.expectation, getCodeForMain(compiler));
        }
      }).catchError((e) {
        print(e);
        Expect.fail('The following test failed to compile:\n'
                    '${formatTest(files)}');
      });
    });
  }
}
