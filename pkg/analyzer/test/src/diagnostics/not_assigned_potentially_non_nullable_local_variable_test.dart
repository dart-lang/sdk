// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      NotInitializedPotentiallyNonNullableLocalVariableTest,
    );
  });
}

@reflectiveTest
class NotInitializedPotentiallyNonNullableLocalVariableTest
    extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_definitelyAssigned_basic() async {
    assertNoErrorsInCode('''
void f() {
  int v;
  v = 0;
  v;
}
''');
  }

  test_definitelyAssigned_if_then() async {
    assertErrorsInCode('''
void f(bool b) {
  int v;
  if (b) {
    v = 1;
  }
  v;
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          23,
          1),
    ]);
  }

  test_definitelyAssigned_if_thenElse_all() async {
    assertNoErrorsInCode('''
void f(bool b) {
  int v;
  if (b) {
    v = 1;
  } else {
    v = 2;
  }
  v;
}
''');
  }

  test_definitelyAssigned_notUsed() async {
    assertNoErrorsInCode('''
void f() {
  int v;
}
''');
  }

  test_futureOr_questionArgument_none() async {
    assertNoErrorsInCode('''
import 'dart:async';

f() {
  FutureOr<int?> v;
}
''');
  }

  test_hasInitializer() async {
    assertNoErrorsInCode('''
f() {
  int v = 0;
}
''');
  }

  test_late() async {
    assertNoErrorsInCode('''
f() {
  late int v;
}
''');
  }

  test_noInitializer() async {
    assertErrorsInCode('''
f() {
  int v;
  v;
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          12,
          1),
    ]);
  }

  test_noInitializer_typeParameter() async {
    assertErrorsInCode('''
f<T>() {
  T v;
  v;
}
''', [
      error(
          CompileTimeErrorCode
              .NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE,
          13,
          1),
    ]);
  }

  test_nullable() async {
    assertNoErrorsInCode('''
f() {
  int? v;
}
''');
  }

  test_type_dynamic() async {
    assertNoErrorsInCode('''
f() {
  dynamic v;
}
''');
  }

  test_type_dynamicImplicit() async {
    assertNoErrorsInCode('''
f() {
  var v;
}
''');
  }

  test_type_void() async {
    assertNoErrorsInCode('''
f() {
  void v;
}
''');
  }
}
