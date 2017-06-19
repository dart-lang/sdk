// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that benign error do not prevent compilation.

import 'memory_compiler.dart';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:expect/expect.dart';

main() {
  asyncTest(() async {
    for (MessageKind kind in Compiler.BENIGN_ERRORS) {
      await testExamples(kind);
    }
  });
}

testExamples(MessageKind kind) async {
  MessageTemplate template = MessageTemplate.TEMPLATES[kind];
  for (var example in template.examples) {
    if (example is! Map) {
      example = {'main.dart': example};
    }
    DiagnosticCollector collector = new DiagnosticCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: example, diagnosticHandler: collector);
    Expect.isTrue(result.isSuccess);
    Expect
        .isTrue(collector.errors.any((message) => message.messageKind == kind));
    Compiler compiler = result.compiler;
    JavaScriptBackend backend = compiler.backend;
    Expect.isNotNull(backend.generatedCode[
        compiler.frontendStrategy.elementEnvironment.mainFunction]);
  }
}
