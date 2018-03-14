// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that tree-shaking hasn't been turned off.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_backend/js_backend.dart' show JavaScriptBackend;
import 'package:compiler/src/js_backend/mirrors_analysis.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';

main() {
  DiagnosticCollector collector = new DiagnosticCollector();
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        diagnosticHandler: collector,
        options: [Flags.useOldFrontend]);
    Compiler compiler = result.compiler;
    JavaScriptBackend backend = compiler.backend;
    Expect.isTrue(collector.errors.isEmpty);
    Expect.isTrue(collector.infos.isEmpty);
    Expect.isFalse(compiler.compilationFailed);
    MirrorsResolutionAnalysisImpl mirrorsResolutionAnalysis =
        backend.mirrorsResolutionAnalysis;
    Expect.isFalse(
        mirrorsResolutionAnalysis.handler.hasEnqueuedReflectiveElements);
    Expect.isFalse(
        mirrorsResolutionAnalysis.handler.hasEnqueuedReflectiveStaticFields);
    MirrorsCodegenAnalysisImpl mirrorsCodegenAnalysis =
        backend.mirrorsCodegenAnalysis;
    Expect
        .isFalse(mirrorsCodegenAnalysis.handler.hasEnqueuedReflectiveElements);
    Expect.isFalse(
        mirrorsCodegenAnalysis.handler.hasEnqueuedReflectiveStaticFields);
    Expect.isFalse(compiler.disableTypeInference);
    Expect.isFalse(backend.mirrorsData.hasRetainedMetadata);
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
