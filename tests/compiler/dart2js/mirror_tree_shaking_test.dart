// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that tree-shaking hasn't been turned off.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_backend/js_backend.dart' show JavaScriptBackend;
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

main() {
  DiagnosticCollector collector = new DiagnosticCollector();
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, diagnosticHandler: collector);
    Compiler compiler = result.compiler;
    JavaScriptBackend backend = compiler.backend;
    Expect.isTrue(collector.errors.isEmpty);
    Expect.isTrue(collector.infos.isEmpty);
    Expect.isFalse(compiler.compilationFailed);
    Expect.isFalse(backend
        .mirrorsAnalysis.resolutionHandler.hasEnqueuedReflectiveElements);
    Expect.isFalse(backend
        .mirrorsAnalysis.resolutionHandler.hasEnqueuedReflectiveStaticFields);
    Expect.isFalse(
        backend.mirrorsAnalysis.codegenHandler.hasEnqueuedReflectiveElements);
    Expect.isFalse(backend
        .mirrorsAnalysis.codegenHandler.hasEnqueuedReflectiveStaticFields);
    Expect.isFalse(compiler.disableTypeInference);
    Expect.isFalse(backend.hasRetainedMetadata);
  });
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
import 'dart:mirrors';

class Foo {
  noSuchMethod(invocation) {
    print('Invoked ${MirrorSystem.getName(invocation.memberName)}');
    return reflect('foobar').delegate(invocation);
  }
}

void main() {
  print(new Foo().substring(3));
}
""",
};
