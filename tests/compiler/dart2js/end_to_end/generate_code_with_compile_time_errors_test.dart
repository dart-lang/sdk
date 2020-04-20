// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the compiler can generates code with compile time error according
// to the compiler options.

library dart2js.test.generate_code_with_compile_time_errors;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_model/js_strategy.dart';
import '../helpers/memory_compiler.dart';
import '../helpers/output_collector.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': ''' 
foo() {
 const [ new List() ];
}

main() {
  foo();
}
''',
};

test(List<String> options,
    {bool expectedOutput,
    bool expectedCodeGenerated,
    bool expectHint: false}) async {
  DiagnosticCollector collector = new DiagnosticCollector();
  OutputCollector outputCollector = new OutputCollector();
  CompilationResult result = await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: collector,
      outputProvider: outputCollector,
      options: options);
  Compiler compiler = result.compiler;
  Expect.isFalse(result.isSuccess, "Expected compilation failure.");
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isFalse(collector.errors.isEmpty, "Expected compile-time errors.");
  Expect.equals(expectHint, collector.hints.isNotEmpty,
      "Unexpected hints: ${collector.warnings}");

  JsBackendStrategy backendStrategy = compiler.backendStrategy;
  bool isCodeGenerated = backendStrategy.generatedCode.isNotEmpty;
  Expect.equals(
      expectedCodeGenerated,
      isCodeGenerated,
      expectedCodeGenerated
          ? "Expected generated code for options $options."
          : "Expected no code generated for options $options.");
  Expect.equals(
      expectedOutput,
      outputCollector.outputMap.isNotEmpty,
      expectedOutput
          ? "Expected output for options $options."
          : "Expected no output for options $options.");
}

void main() {
  asyncTest(() async {
    await test([], expectedCodeGenerated: false, expectedOutput: false);
    await test(['--test-mode'],
        expectedCodeGenerated: false, expectedOutput: false);
    await test(['--generate-code-with-compile-time-errors'],
        expectedCodeGenerated: true, expectedOutput: true);
    await test(['--generate-code-with-compile-time-errors', '--test-mode'],
        expectedCodeGenerated: true, expectedOutput: false);
  });
}
