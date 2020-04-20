// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/world.dart' show KClosedWorld;
import '../helpers/memory_compiler.dart';

const Map<String, String> MEMORY_SOURCE_FILES = const {
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
  runTests() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    Compiler compiler = result.compiler;
    KClosedWorld closedWorld = compiler.frontendClosedWorldForTesting;
    KElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    Expect.isFalse(compiler.compilationFailed, 'Unsuccessful compilation');

    void test(String name,
        {bool expectNoInline: false, bool expectTryInline: false}) {
      LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
      FunctionEntity method =
          elementEnvironment.lookupLibraryMember(mainLibrary, name);
      Expect.isNotNull(method);
      Expect.equals(
          expectNoInline,
          closedWorld.annotationsData.hasNoInline(method),
          "Unexpected annotation of @pragma('dart2js:noInline') on '$method'.");
      Expect.equals(
          expectTryInline,
          closedWorld.annotationsData.hasTryInline(method),
          "Unexpected annotation of @pragma('dart2js:tryInline') on '$method'.");
    }

    test('method');
    test('methodNoInline', expectNoInline: true);
    test('methodTryInline', expectTryInline: true);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
