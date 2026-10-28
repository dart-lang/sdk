// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnGenericInvocationTest);
  });
}

/// Tests of WarningCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnGenericInvocationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(
        experimentalFeatures: experimentalFeatures,
        strictInference: true,
      ),
    );
    writeTestPackageConfigWithMeta();
  }

  test_functionInstantiation_functionInvocation_downwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function<T>(T) g() => <T>(T t) {};
void h(void Function(int) callback) {}
void f() {
  h(g());
}
''');
  }

  test_functionInstantiation_functionInvocation_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function<T, R>(T) g() => <T, R>(T t) {};
void h(void Function(int) callback) {}
void f() {
  h(g());
//  ^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'void Function<T, R>(T)' can't be inferred.
}
''');
  }

  test_functionInstantiation_methodInvocation_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void Function<T, R>(T) g() => <T, R>(T t) {};
}
void h(void Function(int) callback) {}
void f(A a) {
  h(a.g());
//  ^^^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'void Function<T, R>(T)' can't be inferred.
}
''');
  }

  test_functionInstantiation_parenthesizedFunctionInvocation_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function<T, R>(T) g() => <T, R>(T t) {};
void h(void Function(int) callback) {}
void f() {
  h((g()));
//   ^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'void Function<T, R>(T)' can't be inferred.
}
''');
  }

  test_functionInvocationResult_callable_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call<T>() {}
}

C g() => C();

void f() {
  g()();
//^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'C' can't be inferred.
}
''');
  }

  test_functionInvocationResult_immediatelyCast() async {
    await resolveTestCodeWithDiagnostics(r'''
T Function<T>() g() => <T>() => throw 0;

void f() {
  g()() as int;
}
''');
  }

  test_functionInvocationResult_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function<T>() g() => <T>() {};

void f() {
  g()();
//^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'void Function<T>()' can't be inferred.
}
''');
  }

  test_genericFunctionExpression_downwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
int f(T Function<T>()? m, T Function<T>() n) {
  return (m ?? n)();
}
''');
  }

  test_genericFunctionExpression_explicitTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function<T>()? m, void Function<T>() n) {
  (m ?? n)<int>();
}
''');
  }

  test_genericFunctionExpression_immediatelyCast() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(T Function<T>()? m, T Function<T>() n) {
  (m ?? n)() as int;
}
''');
  }

  test_genericFunctionExpression_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function<T>()? m, void Function<T>() n) {
  (m ?? n)();
//^^^^^^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'void Function<T>()' can't be inferred.
}
''');
  }

  test_genericFunctionExpression_upwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function<T>(T a)? m, void Function<T>(T a) n) {
  (m ?? n)(1);
}
''');
  }

  test_genericFunctionExpressionLiteral_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  (<T>() {})();
//^^^^^^^^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'Null Function<T>()' can't be inferred.
}
''');
  }

  test_implicitCallTearOff_functionInvocation_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void call<T, R>(T t) {}
}
C g() => C();
void h(void Function(int) callback) {}
void f() {
  h(g());
//  ^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'C' can't be inferred.
}
''');
  }

  test_methodInvocationResult_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void Function<T>() g() => <T>() {};
}

void f(A a) {
  a.g()();
//^^^^^
// [diag.inferenceFailureOnGenericInvocation] The type argument(s) of the generic function type 'void Function<T>()' can't be inferred.
}
''');
  }
}
