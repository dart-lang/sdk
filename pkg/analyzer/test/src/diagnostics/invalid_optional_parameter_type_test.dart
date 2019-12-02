// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOptionalParameterTypeTest);
  });
}

@reflectiveTest
class InvalidOptionalParameterTypeTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_fieldFormalParameter_named_optional() async {
    await assertErrorsInCode('''
class A {
  dynamic f;
  A(void this.f({int a, int? b}));
}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 44, 1),
    ]);
  }

  test_fieldFormalParameter_positional_optional() async {
    await assertErrorsInCode('''
class A {
  dynamic f;
  A(void this.f([int a, int? b]));
}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 44, 1),
    ]);
  }

  test_functionTypeAlias_named_optional() async {
    await assertErrorsInCode('''
typedef void F({int a, int? b});
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 20, 1),
    ]);
  }

  test_functionTypeAlias_positional_optional() async {
    await assertErrorsInCode('''
typedef void F([int a, int? b]);
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 20, 1),
    ]);
  }

  test_functionTypedFormalParameter_named_optional() async {
    await assertErrorsInCode('''
void f(void p({int a, int? b})) {}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 19, 1),
    ]);
  }

  test_functionTypedFormalParameter_positional_optional() async {
    await assertErrorsInCode('''
void f(void p([int a, int? b])) {}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 19, 1),
    ]);
  }

  test_genericFunctionType_named_optional() async {
    await assertErrorsInCode('''
void f(void Function({int a, int? b}) p) {}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 26, 1),
    ]);
  }

  test_genericFunctionType_positional_optional() async {
    await assertErrorsInCode('''
void f(void Function([int a, int? b]) p) {}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 26, 1),
    ]);
  }

  test_genericFunctionType_positional_optional2() async {
    await assertErrorsInCode('''
void f(void Function([int, int?]) p) {}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 22, 3),
    ]);
  }

  test_typeParameter_potentiallyNonNullable_named_optional() async {
    await assertErrorsInCode('''
class A<T extends Object?> {
  void f({T a}) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 41, 1),
    ]);
  }

  test_typeParameter_potentiallyNonNullable_positional_optional() async {
    await assertErrorsInCode('''
class A<T extends Object?> {
  void f([T a]) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OPTIONAL_PARAMETER_TYPE, 41, 1),
    ]);
  }
}
