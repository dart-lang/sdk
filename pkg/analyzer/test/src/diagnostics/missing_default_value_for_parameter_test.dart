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
    defineReflectiveTests(MissingDefaultValueForParameterTest);
  });
}

@reflectiveTest
class MissingDefaultValueForParameterTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_class_nonNullable_named_optional_default() async {
    await assertNoErrorsInCode('''
void f({int a = 0}) {}
''');
  }

  test_class_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
void f({int a}) {}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 12, 1),
    ]);
  }

  test_class_nonNullable_named_required() async {
    await assertNoErrorsInCode('''
void f({required int a}) {}
''');
  }

  test_class_nonNullable_positional_optional_default() async {
    await assertNoErrorsInCode('''
void f([int a = 0]) {}
''');
  }

  test_class_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
void f([int a]) {}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 12, 1),
    ]);
  }

  test_class_nonNullable_positional_required() async {
    await assertNoErrorsInCode('''
void f(int a) {}
''');
  }

  test_class_nullable_named_optional_default() async {
    await assertNoErrorsInCode('''
void f({int? a = 0}) {}
''');
  }

  test_class_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
void f({int? a}) {}
''');
  }

  test_class_nullable_named_required() async {
    await assertNoErrorsInCode('''
void f({required int? a}) {}
''');
  }

  test_class_nullable_positional_optional_default() async {
    await assertNoErrorsInCode('''
void f([int? a = 0]) {}
''');
  }

  test_class_nullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
void f([int? a]) {}
''');
  }

  test_class_nullable_positional_required() async {
    await assertNoErrorsInCode('''
void f(int? a) {}
''');
  }

  test_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
class A {
  final log;
  A(void this.log({String s})) {}
}
''');
  }

  test_functionTypeAlias() async {
    await assertNoErrorsInCode('''
typedef void log({String});
''');
  }

  test_functionTypedParameter() async {
    await assertNoErrorsInCode('''
void printToLog(void log({String})) {}
''');
  }

  test_genericFunctionType() async {
    await assertNoErrorsInCode('''
void Function({String s})? log;
''');
  }

  test_typeParameter_nullable_named_optional_default() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f({T? a = null}) {}
}
''');
  }

  test_typeParameter_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f({T? a}) {}
}
''');
  }

  test_typeParameter_nullable_named_required() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f({required T? a}) {}
}
''');
  }

  test_typeParameter_nullable_positional_optional_default() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f([T? a = null]) {}
}
''');
  }

  test_typeParameter_nullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f([T? a]) {}
}
''');
  }

  test_typeParameter_nullable_positional_required() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f(T? a) {}
}
''');
  }

  test_typeParameter_potentiallyNonNullable_named_required() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f({required T a}) {}
}
''');
  }

  test_typeParameter_potentiallyNonNullable_positional_required() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  void f(T a) {}
}
''');
  }
}
