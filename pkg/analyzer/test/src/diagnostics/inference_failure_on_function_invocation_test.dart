// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnFunctionInvocationTest);
  });
}

/// Tests of WarningCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION with the
/// "strict-inference" static analysis option.
@reflectiveTest
class InferenceFailureOnFunctionInvocationTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictInference: true),
    );
    writeTestPackageConfigWithMeta();
  }

  test_functionType_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function<T>() m) {
  m();
//^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'm' can't be inferred.
}
''');
  }

  test_functionType_notGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(void Function() m) {
  m();
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

  test_genericMethod_downwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  T m<T>();
}

int f(C c) {
  return c.m();
}
''');
  }

  test_genericMethod_explicitTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  void m<T>();
}

void f(C c) {
  c.m<int>();
}
''');
  }

  test_genericMethod_immediatelyCast() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  T m<T>();
}

void f(C c) {
  c.m() as int;
}
''');
  }

  test_genericMethod_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  void m<T>();
}

void f(C c) {
  c.m();
//  ^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'm' can't be inferred.
}
''');
  }

  test_genericMethod_optionalTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
abstract class C {
  @optionalTypeArgs
  void m<T>();
}

void f(C c) {
  c.m();
}
''');
  }

  test_genericMethod_upwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  void m<T>(T a);
}

void f(C c) {
  c.m(7);
}
''');
  }

  test_genericMethodDotShorthand_downwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static C m<T>() => C();
}

C f() {
  return .m();
//        ^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'm' can't be inferred.
}
''');
  }

  test_genericMethodDotShorthand_explicitTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static C m<T>() => C();
}

C f() {
  return .m<int>();
}
''');
  }

  test_genericStaticMethod_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void m<T>() {}
}

void f() {
  C.m();
//  ^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'm' can't be inferred.
}
''');
  }

  test_genericTypedef_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Fn = void Function<T>();
void g(Fn fn) {
  fn();
//^^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'fn' can't be inferred.
}
''');
  }

  test_genericTypedef_optionalTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
typedef Fn = void Function<T>();
void g(Fn fn) {
  fn();
}
''');
  }

  test_localFunction_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g<T>() {}
  g();
//^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'g' can't be inferred.
}
''');
  }

  test_localFunctionVariable_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var m = <T>() {};
  m();
//^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'm' can't be inferred.
}
''');
  }

  test_nonGenericMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  void m();
}

void f(C c) {
  c.m();
}
''');
  }

  test_topLevelFunction_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>() {}

void g() {
  f();
//^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'f' can't be inferred.
}
''');
  }

  test_topLevelFunction_withImportPrefix_noInference() async {
    newFile('$testPackageLibPath/a.dart', '''
void f<T>() {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as a;
void g() {
  a.f();
//  ^
// [diag.inferenceFailureOnFunctionInvocation] The type argument(s) of the function 'f' can't be inferred.
}
''');
  }

  test_topLevelFunction_withImportPrefix_optionalTypeArgs() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'package:meta/meta.dart';
@optionalTypeArgs
void f<T>() {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as a;
void g() {
  a.f();
}
''');
  }
}
