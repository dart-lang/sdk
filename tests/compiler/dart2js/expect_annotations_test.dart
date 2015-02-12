// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2jslib.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/types/types.dart';
import 'type_mask_test_helper.dart';
import 'memory_compiler.dart';

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
import 'package:expect/expect.dart';

int method(String arg) => arg.length;

@AssumeDynamic()
int methodAssumeDynamic(String arg) => arg.length;

@TrustTypeAnnotations()
int methodTrustTypeAnnotations(String arg) => arg.length;

@NoInlining()
int methodNoInlining(String arg) => arg.length;

@NoInlining() @TrustTypeAnnotations()
int methodNoInliningTrustTypeAnnotations(String arg) => arg.length;

@AssumeDynamic() @TrustTypeAnnotations()
int methodAssumeDynamicTrustTypeAnnotations(String arg) => arg.length;


void main(List<String> args) {
  print(method(args[0]));
  print(methodAssumeDynamic('foo'));
  print(methodTrustTypeAnnotations(42));
  print(methodTrustTypeAnnotations("fourtyTwo"));
  print(methodNoInlining('bar'));
  print(methodNoInliningTrustTypeAnnotations(42));
  print(methodNoInliningTrustTypeAnnotations("fourtyTwo"));
  print(methodAssumeDynamicTrustTypeAnnotations(null));
}
"""
};

main() {
  Compiler compiler = compilerFor(MEMORY_SOURCE_FILES);
  asyncTest(() => compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
    Expect.isFalse(compiler.compilationFailed, 'Unsuccessful compilation');
    JavaScriptBackend backend = compiler.backend;
    Expect.isNotNull(backend.annotations.expectNoInliningClass,
        'NoInliningClass is unresolved.');
    Expect.isNotNull(backend.annotations.expectTrustTypeAnnotationsClass,
        'TrustTypeAnnotations is unresolved.');
    Expect.isNotNull(backend.annotations.expectAssumeDynamicClass,
        'AssumeDynamicClass is unresolved.');

    void testTypeMatch(FunctionElement function, TypeMask expectedParameterType,
                       TypeMask expectedReturnType, TypesInferrer inferrer) {
      for (ParameterElement parameter in function.parameters) {
        TypeMask type = inferrer.getTypeOfElement(parameter);
        Expect.equals(expectedParameterType, simplify(type, compiler),
            "$parameter");
      }
      if (expectedReturnType != null) {
        TypeMask type = inferrer.getReturnTypeOfElement(function);
        Expect.equals(expectedReturnType, simplify(type, compiler),
            "$function");
      }
    }

    void test(String name,
              {bool expectNoInlining: false,
               bool expectTrustTypeAnnotations: false,
               TypeMask expectedParameterType: null,
               TypeMask expectedReturnType: null,
               bool expectAssumeDynamic: false}) {
       Element method = compiler.mainApp.find(name);
       Expect.isNotNull(method);
       Expect.equals(
           expectNoInlining,
           backend.annotations.noInlining(method),
           "Unexpected annotation of @NoInlining on '$method'.");
       Expect.equals(
           expectTrustTypeAnnotations,
           backend.annotations.trustTypeAnnotations(method),
           "Unexpected annotation of @TrustTypeAnnotations on '$method'.");
       Expect.equals(
           expectAssumeDynamic,
           backend.annotations.assumeDynamic(method),
           "Unexpected annotation of @AssumeDynamic on '$method'.");
       TypesInferrer inferrer = compiler.typesTask.typesInferrer;
       if (expectTrustTypeAnnotations && expectedParameterType != null) {
         testTypeMatch(method, expectedParameterType, expectedReturnType,
             inferrer);
       } else if (expectAssumeDynamic) {
         testTypeMatch(method, compiler.typesTask.dynamicType, null, inferrer);
       }
    }

    TypeMask jsStringType = compiler.typesTask.stringType;
    TypeMask jsIntType = compiler.typesTask.intType;
    TypeMask coreStringType = new TypeMask.subtype(compiler.stringClass,
        compiler.world);

    test('method');
    test('methodAssumeDynamic', expectAssumeDynamic: true);
    test('methodTrustTypeAnnotations',
        expectTrustTypeAnnotations: true,
        expectedParameterType: jsStringType);
    test('methodNoInlining', expectNoInlining: true);
    test('methodNoInliningTrustTypeAnnotations',
         expectNoInlining: true,
         expectTrustTypeAnnotations: true,
         expectedParameterType: jsStringType,
         expectedReturnType: jsIntType);
    test('methodAssumeDynamicTrustTypeAnnotations',
         expectAssumeDynamic: true,
         expectTrustTypeAnnotations: true,
         expectedParameterType: coreStringType);

  }));
}
