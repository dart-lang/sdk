// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/annotations.dart' as optimizerHints;
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;
import '../type_mask_test_helper.dart';
import '../memory_compiler.dart';

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
import 'package:expect/expect.dart';

int method(String arg) => arg.length;

@AssumeDynamic()
int methodAssumeDynamic(String arg) => arg.length;

@TrustTypeAnnotations()
int methodTrustTypeAnnotations(String arg) => arg.length;

@NoInline()
int methodNoInline(String arg) => arg.length;

@NoInline() @TrustTypeAnnotations()
int methodNoInlineTrustTypeAnnotations(String arg) => arg.length;

@AssumeDynamic() @TrustTypeAnnotations()
int methodAssumeDynamicTrustTypeAnnotations(String arg) => arg.length;


void main(List<String> args) {
  print(method(args[0]));
  print(methodAssumeDynamic('foo'));
  print(methodTrustTypeAnnotations(42));
  print(methodTrustTypeAnnotations("fourtyTwo"));
  print(methodNoInline('bar'));
  print(methodNoInlineTrustTypeAnnotations(42));
  print(methodNoInlineTrustTypeAnnotations("fourtyTwo"));
  print(methodAssumeDynamicTrustTypeAnnotations(null));
}
"""
};

main() {
  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}

runTest({bool useKernel}) async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      options: useKernel ? [Flags.useKernel] : []);
  Compiler compiler = result.compiler;
  ClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  Expect.isFalse(compiler.compilationFailed, 'Unsuccessful compilation');
  Expect.isNotNull(closedWorld.commonElements.expectNoInlineClass,
      'NoInlineClass is unresolved.');
  Expect.isNotNull(closedWorld.commonElements.expectTrustTypeAnnotationsClass,
      'TrustTypeAnnotations is unresolved.');
  Expect.isNotNull(closedWorld.commonElements.expectAssumeDynamicClass,
      'AssumeDynamicClass is unresolved.');

  void testTypeMatch(FunctionEntity function, TypeMask expectedParameterType,
      TypeMask expectedReturnType, TypesInferrer inferrer) {
    compiler.codegenWorldBuilder.forEachParameterAsLocal(function,
        (Local parameter) {
      TypeMask type = inferrer.getTypeOfParameter(parameter);
      Expect.equals(
          expectedParameterType, simplify(type, closedWorld), "$parameter");
    });
    if (expectedReturnType != null) {
      TypeMask type = inferrer.getReturnTypeOfMember(function);
      Expect.equals(
          expectedReturnType, simplify(type, closedWorld), "$function");
    }
  }

  void test(String name,
      {bool expectNoInline: false,
      bool expectTrustTypeAnnotations: false,
      TypeMask expectedParameterType: null,
      TypeMask expectedReturnType: null,
      bool expectAssumeDynamic: false}) {
    LibraryEntity mainApp = closedWorld.elementEnvironment.mainLibrary;
    FunctionEntity method =
        closedWorld.elementEnvironment.lookupLibraryMember(mainApp, name);
    Expect.isNotNull(method);
    Expect.equals(
        expectNoInline,
        optimizerHints.noInline(
            closedWorld.elementEnvironment, closedWorld.commonElements, method),
        "Unexpected annotation of @NoInline on '$method'.");
    Expect.equals(
        expectTrustTypeAnnotations,
        optimizerHints.trustTypeAnnotations(
            closedWorld.elementEnvironment, closedWorld.commonElements, method),
        "Unexpected annotation of @TrustTypeAnnotations on '$method'.");
    Expect.equals(
        expectAssumeDynamic,
        optimizerHints.assumeDynamic(
            closedWorld.elementEnvironment, closedWorld.commonElements, method),
        "Unexpected annotation of @AssumeDynamic on '$method'.");
    TypesInferrer inferrer = compiler.globalInference.typesInferrerInternal;
    if (expectTrustTypeAnnotations && expectedParameterType != null) {
      testTypeMatch(
          method, expectedParameterType, expectedReturnType, inferrer);
    } else if (expectAssumeDynamic) {
      testTypeMatch(
          method, closedWorld.commonMasks.dynamicType, null, inferrer);
    }
  }

  TypeMask jsStringType = closedWorld.commonMasks.stringType;
  TypeMask jsIntType = closedWorld.commonMasks.intType;
  TypeMask coreStringType =
      new TypeMask.subtype(closedWorld.commonElements.stringClass, closedWorld);

  test('method');
  test('methodAssumeDynamic', expectAssumeDynamic: true);
  test('methodTrustTypeAnnotations',
      expectTrustTypeAnnotations: true, expectedParameterType: jsStringType);
  test('methodNoInline', expectNoInline: true);
  test('methodNoInlineTrustTypeAnnotations',
      expectNoInline: true,
      expectTrustTypeAnnotations: true,
      expectedParameterType: jsStringType,
      expectedReturnType: jsIntType);
  test('methodAssumeDynamicTrustTypeAnnotations',
      expectAssumeDynamic: true,
      expectTrustTypeAnnotations: true,
      expectedParameterType: coreStringType);
}
