// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the CPS IR code generator compiles programs and produces the
// the expected output.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;
import 'memory_compiler.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    Element;

const String TEST_MAIN_FILE = 'test.dart';

class TestEntry {
  final String source;
  final String expectation;
  final String elementName;

  const TestEntry(this.source, [this.expectation])
    : elementName = null;

  const TestEntry.forMethod(this.elementName,
      this.source, this.expectation);
}

String formatTest(Map test) {
  return test[TEST_MAIN_FILE];
}

String getCodeForMain(CompilerImpl compiler) {
  Element mainFunction = compiler.mainFunction;
  js.Node ast = compiler.enqueuer.codegen.generatedCode[mainFunction];
  return js.prettyPrint(ast, compiler).getText();
}

String getCodeForMethod(CompilerImpl compiler,
                        String name) {
  Element foundElement;
  for (Element element in compiler.enqueuer.codegen.generatedCode.keys) {
    if (element.toString() == name) {
      if (foundElement != null) {
        Expect.fail('Multiple compiled elements are called $name');
      }
      foundElement = element;
    }
  }

  if (foundElement == null) {
    Expect.fail('There is no compiled element called $name');
  }

  js.Node ast = compiler.enqueuer.codegen.generatedCode[foundElement];
  return js.prettyPrint(ast, compiler).getText();
}

runTests(List<TestEntry> tests) {
  for (TestEntry test in tests) {
    Map files = {TEST_MAIN_FILE: test.source};
    asyncTest(() async {
      Uri uri = Uri.parse('memory:$TEST_MAIN_FILE');
      try {
        CompilationResult result = await runCompiler(
            entryPoint: uri,
            memorySourceFiles: files,
            options: <String>['--use-cps-ir']);
        Expect.isTrue(result.isSuccess);
        CompilerImpl compiler = result.compiler;
        String expectation = test.expectation;
        if (expectation != null) {
          String expected = test.expectation;
          String found = test.elementName == null
              ? getCodeForMain(compiler)
              : getCodeForMethod(compiler, test.elementName);
          if (expected != found) {
            Expect.fail('Expected:\n$expected\nbut found\n$found');
          }
        }
      } catch (e, st) {
        print(e);
        print(st);
        Expect.fail('The following test failed to compile:\n'
                    '${formatTest(files)}');
      }
    });
  }
}
