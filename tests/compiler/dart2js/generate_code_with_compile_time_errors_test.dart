// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can generates code with compile time error according
// to the compiler options.

library dart2js.test.generate_code_with_compile_time_errors;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dart_backend/dart_backend.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'memory_compiler.dart';
import 'output_collector.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': ''' 
foo() {
 const list = [];
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
  Expect.isFalse(
      result.isSuccess,
      "Expected compilation failure.");
  Expect.isTrue(
      collector.warnings.isEmpty,
      "Unexpected warnings: ${collector.warnings}");
  Expect.isFalse(
      collector.errors.isEmpty,
      "Expected compile-time errors.");
  Expect.equals(
      expectHint,
      collector.hints.isNotEmpty,
      "Unexpected hints: ${collector.warnings}");

  bool isCodeGenerated;
  if (options.contains('--output-type=dart')) {
    DartBackend backend = compiler.backend;
    isCodeGenerated = backend.outputter.libraryInfo != null;
  } else {
    JavaScriptBackend backend = compiler.backend;
    isCodeGenerated = backend.generatedCode.isNotEmpty;
  }
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
    await test(
       [],
       expectedCodeGenerated: false,
       expectedOutput: false);
    await test(
       ['--test-mode'],
       expectedCodeGenerated: false,
       expectedOutput: false);
    await test(
       ['--generate-code-with-compile-time-errors'],
       expectedCodeGenerated: true,
       expectedOutput: true);
    await test(
       ['--generate-code-with-compile-time-errors', '--test-mode'],
       expectedCodeGenerated: true,
       expectedOutput: false);

    await test(
       ['--use-cps-ir'],
       expectedCodeGenerated: false,
       expectedOutput: false);
    await test(
       ['--use-cps-ir', '--test-mode'],
       expectedCodeGenerated: false,
       expectedOutput: false);
    await test(
       ['--use-cps-ir', '--generate-code-with-compile-time-errors'],
       expectedCodeGenerated: false,
       expectedOutput: false,
       expectHint: true);
    await test(
       ['--use-cps-ir',
        '--generate-code-with-compile-time-errors',
        '--test-mode'],
       expectedCodeGenerated: false,
       expectedOutput: false,
       expectHint: true);

    await test(
       ['--output-type=dart'],
       expectedCodeGenerated: false,
       expectedOutput: false);
    await test(
       ['--output-type=dart', '--test-mode'],
       expectedCodeGenerated: false,
       expectedOutput: false);
    await test(
       ['--output-type=dart', '--generate-code-with-compile-time-errors'],
       expectedCodeGenerated: false,
       expectedOutput: false,
       expectHint: true);
    await test(
       ['--output-type=dart',
        '--generate-code-with-compile-time-errors',
        '--test-mode'],
       expectedCodeGenerated: false,
       expectedOutput: false,
       expectHint: true);
  });
}
