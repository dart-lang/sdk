// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/inferrer/types.dart';
import 'package:compiler/src/world.dart' show JClosedWorld;
import '../inference/type_mask_test_helper.dart';
import '../helpers/memory_compiler.dart';

const Map<String, String> MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
import 'package:expect/expect.dart';

int method(String arg) => arg.length;

@AssumeDynamic()
int methodAssumeDynamic(String arg) => arg.length;

@NoInline()
int methodNoInline(String arg) => arg.length;

void main(List<String> args) {
  print(method(args[0]));
  print(methodAssumeDynamic('foo'));
  print(methodNoInline('bar'));
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
  Expect.isNotNull(closedWorld.commonElements.expectNoInlineClass,
      'NoInlineClass is unresolved.');
  Expect.isNotNull(closedWorld.commonElements.expectAssumeDynamicClass,
      'AssumeDynamicClass is unresolved.');

  void testTypeMatch(FunctionEntity function, TypeMask expectedParameterType,
      TypeMask expectedReturnType, GlobalTypeInferenceResults results) {
    compiler.codegenWorldBuilder.forEachParameterAsLocal(function,
        (Local parameter) {
      TypeMask type = results.resultOfParameter(parameter);
      Expect.equals(
          expectedParameterType, simplify(type, closedWorld), "$parameter");
    });
    if (expectedReturnType != null) {
      TypeMask type = results.resultOfMember(function).returnType;
      Expect.equals(
          expectedReturnType, simplify(type, closedWorld), "$function");
    }
  }

  void test(String name,
      {bool expectNoInline: false,
      TypeMask expectedParameterType: null,
      TypeMask expectedReturnType: null,
      bool expectAssumeDynamic: false}) {
    LibraryEntity mainApp = closedWorld.elementEnvironment.mainLibrary;
    FunctionEntity method =
        closedWorld.elementEnvironment.lookupLibraryMember(mainApp, name);
    Expect.isNotNull(method);
    Expect.equals(
        expectNoInline,
        closedWorld.annotationsData.nonInlinableFunctions.contains(method),
        "Unexpected annotation of @NoInline() on '$method'.");
    Expect.equals(
        expectAssumeDynamic,
        closedWorld.annotationsData.assumeDynamicMembers.contains(method),
        "Unexpected annotation of @AssumeDynamic() on '$method'.");
    GlobalTypeInferenceResults results =
        compiler.globalInference.resultsForTesting;
    if (expectAssumeDynamic) {
      testTypeMatch(
          method, closedWorld.abstractValueDomain.dynamicType, null, results);
    }
  }

  test('method');
  test('methodAssumeDynamic', expectAssumeDynamic: true);
  test('methodNoInline', expectNoInline: true);
}
