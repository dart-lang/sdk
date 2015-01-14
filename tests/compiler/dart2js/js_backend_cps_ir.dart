// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the CPS IR code generator compiles programs and produces the
// the expected output.

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

String formatTest(Map test) {
  return test[TEST_MAIN_FILE];
}

String getCodeForMain(Compiler compiler) {
  Element mainFunction = compiler.mainFunction;
  js.Node ast = compiler.enqueuer.codegen.generatedCode[mainFunction];
  return js.prettyPrint(ast, compiler).getText();
}


runTests(List<TestEntry> tests) {
  Expect.isTrue(const bool.fromEnvironment("USE_CPS_IR"));

  for (TestEntry test in tests) {
    Map files = {TEST_MAIN_FILE: test.source};
    asyncTest(() {
      Compiler compiler = compilerFor(files);
      Uri uri = Uri.parse('memory:$TEST_MAIN_FILE');
      return compiler.run(uri).then((bool success) {
        Expect.isTrue(success);
        String expectation = test.expectation;
        if (expectation != null) {
          String expected = test.expectation;
          String found = getCodeForMain(compiler);
          if (expected != found) {
            Expect.fail('Expected:\n$expected\nbut found\n$found');
          }
        }
      }).catchError((e) {
        print(e);
        Expect.fail('The following test failed to compile:\n'
                    '${formatTest(files)}');
      });
    });
  }
}
