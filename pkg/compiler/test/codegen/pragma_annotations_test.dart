// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/world.dart' show JClosedWorld;
import '../helpers/memory_compiler.dart';

const Map<String, String> MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
int method(String arg) => arg.length;

@pragma('dart2js:noInline')
int methodNoInline(String arg) => arg.length;

@pragma('dart2js:tryInline')
int methodTryInline(String arg) {
  return arg.length;
}

void main(List<String> args) {
  print(method(args[0]));
  print(method('bar'));
  print(methodNoInline(args[0]));
  print(methodNoInline('bar'));
  print(methodTryInline(args[0]));
  print(methodTryInline('bar'));
}
"""
};

main() {
  asyncTest(() async {
    await runTest();
  });
}

runTest() async {
  CompilationResult result =
      await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
  Compiler compiler = result.compiler;
  JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  Expect.isFalse(compiler.compilationFailed, 'Unsuccessful compilation');

  void test(String name,
      {bool expectNoInline: false, bool expectTryInline: false}) {
    LibraryEntity mainApp = closedWorld.elementEnvironment.mainLibrary;
    FunctionEntity method =
        closedWorld.elementEnvironment.lookupLibraryMember(mainApp, name);
    Expect.isNotNull(method, "Cannot find method '$name'");
    Expect.equals(
        expectNoInline,
        closedWorld.annotationsData.hasNoInline(method),
        "Unexpected annotation of 'noInline' on '$method'.");
    Expect.equals(
        expectTryInline,
        closedWorld.annotationsData.hasTryInline(method),
        "Unexpected annotation of 'tryInline' on '$method'.");
  }

  test('method');
  test('methodNoInline', expectNoInline: true);
  test('methodTryInline', expectTryInline: true);
}
