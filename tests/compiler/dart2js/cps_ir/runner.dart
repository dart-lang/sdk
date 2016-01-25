// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the CPS IR code generator compiles programs and produces the
// the expected output.

import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;
import '../memory_compiler.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    Element;

// Regular experession used to extract the method name that is used to match the
// test output. By default we match the output of main.
final RegExp elementNameRegExp = new RegExp(r'^// Method to test: (.*)$',
    multiLine: true);

runTest(String filename, {bool update: false}) {
  var outputname = filename.replaceFirst('.dart', '.js');
  String source = new File.fromUri(Platform.script.resolve('input/$filename'))
      .readAsStringSync();
  var expectedFile =
      new File.fromUri(Platform.script.resolve('expected/$outputname'));
  String expected = expectedFile.existsSync()
    ? expectedFile.readAsStringSync() : '';
  var match = elementNameRegExp.firstMatch(source);
  var elementName = match?.group(1);

  Map files = {
      TEST_MAIN_FILE: source,
      'package:expect/expect.dart': '''
          class NoInline {
            const NoInline();
          }
          class TrustTypeAnnotations {
            const TrustTypeAnnotations();
          }
          class AssumeDynamic {
            const AssumeDynamic();
          }
       ''',
   };
  asyncTest(() async {
    Uri uri = Uri.parse('memory:$TEST_MAIN_FILE');
    String found = null;
    try {
      CompilationResult result = await runCompiler(
          entryPoint: uri,
          memorySourceFiles: files,
          options: <String>['--use-cps-ir']);
      Expect.isTrue(result.isSuccess);
      CompilerImpl compiler = result.compiler;
      if (expected != null) {
        String output = elementName == null
            ? _getCodeForMain(compiler)
            : _getCodeForMethod(compiler, elementName);
        // Include the input in a comment of the expected file to make it easier
        // to see the relation between input and output in code reviews.
        found = '// Expectation for test: \n'
            '// ${source.trim().replaceAll('\n', '\n// ')}\n\n'
            '$output\n';
      }
    } catch (e, st) {
      print(e);
      print(st);
      var message = 'The following test failed to compile:\n'
                    '${_formatTest(files)}';
      if (update) {
        print('\n\n$message\n');
        return;
      } else {
        Expect.fail(message);
      }
    }
    if (expected != found) {
      if (update) {
        expectedFile.writeAsStringSync(found);
        print('INFO: $expectedFile was updated');
      } else {
        Expect.fail('Unexpected output for test:\n  '
            '${_formatTest(files).replaceAll('\n', '\n  ')}\n'
            'Expected:\n  ${expected.replaceAll('\n', '\n  ')}\n'
            'but found:\n  ${found?.replaceAll('\n', '\n  ')}\n'
            '$regenerateCommand');
      }
    }
  });
}

String get regenerateCommand {
  var flags = Platform.packageRoot == null
    ? '' : '--package-root=${Platform.packageRoot} ';
  return '''
If you wish to update the test expectations, rerun this test passing "update" as
an argument, as follows:

  dart $flags${Platform.script} update

If you want to update more than one test at once, run:
  dart $flags${Platform.script.resolve('update_all.dart')}

''';
}

const String TEST_MAIN_FILE = 'test.dart';

String _formatTest(Map test) {
  return test[TEST_MAIN_FILE];
}

String _getCodeForMain(CompilerImpl compiler) {
  Element mainFunction = compiler.mainFunction;
  js.Node ast = compiler.enqueuer.codegen.generatedCode[mainFunction];
  return js.prettyPrint(ast, compiler);
}

String _getCodeForMethod(CompilerImpl compiler,
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
  return js.prettyPrint(ast, compiler);
}
