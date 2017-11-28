// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/js_backend/annotations.dart' as optimizerHints;
import 'package:compiler/src/world.dart' show ClosedWorld;
import 'memory_compiler.dart';

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
import 'package:meta/dart2js.dart';

int method(String arg) => arg.length;

@noInline
int methodNoInline(String arg) => arg.length;

@tryInline
int methodTryInline(String arg) => arg.length;


void main(List<String> args) {
  print(method(args[0]));
  print(methodNoInline('bar'));
  print(methodTryInline('bar'));
}
"""
};

main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    Compiler compiler = result.compiler;
    ClosedWorld closedWorld =
        compiler.resolutionWorldBuilder.closedWorldForTesting;
    Expect.isFalse(compiler.compilationFailed, 'Unsuccessful compilation');
    Expect.isNotNull(closedWorld.commonElements.metaNoInlineClass,
        'NoInlineClass is unresolved.');
    Expect.isNotNull(closedWorld.commonElements.metaTryInlineClass,
        'TryInlineClass is unresolved.');

    void test(String name,
        {bool expectNoInline: false, bool expectTryInline: false}) {
      LibraryElement mainApp =
          compiler.frontendStrategy.elementEnvironment.mainLibrary;
      MethodElement method = mainApp.find(name);
      Expect.isNotNull(method);
      Expect.equals(
          expectNoInline,
          optimizerHints.noInline(closedWorld.elementEnvironment,
              closedWorld.commonElements, method),
          "Unexpected annotation of @noInline on '$method'.");
      Expect.equals(
          expectTryInline,
          optimizerHints.tryInline(closedWorld.elementEnvironment,
              closedWorld.commonElements, method),
          "Unexpected annotation of @tryInline on '$method'.");
    }

    test('method');
    test('methodNoInline', expectNoInline: true);
    test('methodTryInline', expectTryInline: true);
  });
}
