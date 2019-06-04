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
    defineReflectiveTests(ArgumentTypeNotAssignableTest);
    defineReflectiveTests(ArgumentTypeNotAssignableTest_NNBD);
  });
}

@reflectiveTest
class ArgumentTypeNotAssignableTest extends DriverResolutionTest {
  test_functionType() async {
    await assertErrorsInCode(r'''
m() {
  var a = new A();
  a.n(() => 0);
}
class A {
  n(void f(int i)) {}
}
''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 31, 7),
    ]);
  }

  test_interfaceType() async {
    await assertErrorsInCode(r'''
m() {
  var i = '';
  n(i);
}
n(int i) {}
''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 24, 1),
    ]);
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableTest_NNBD extends ArgumentTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_downcast() async {
    await assertErrorsInCode(r'''
m() {
  num y = 1;
  n(y);
}
n(int x) {}
''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 23, 1),
    ]);
  }

  @failingTest
  test_downcast_nullableNonNullable() async {
    await assertErrorsInCode(r'''
m() {
  int? y;
  n(y);
}
n(int x) {}
''', [
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 24, 1),
    ]);
  }

  test_dynamicCast() async {
    await assertNoErrorsInCode(r'''
m() {
  dynamic i;
  n(i);
}
n(int i) {}
''');
  }
}
