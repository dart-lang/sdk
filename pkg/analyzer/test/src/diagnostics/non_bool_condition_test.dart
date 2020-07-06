// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolConditionTest);
    defineReflectiveTests(NonBoolConditionTest_NNBD);
  });
}

@reflectiveTest
class NonBoolConditionTest extends DriverResolutionTest {
  test_conditional() async {
    await assertErrorsInCode('''
f() { return 3 ? 2 : 1; }
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 13, 1),
    ]);
  }

  test_do() async {
    await assertErrorsInCode(r'''
f() {
  do {} while (3);
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 21, 1),
    ]);
  }

  test_for() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (;3;) {}
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 14, 1),
    ]);
  }

  test_forElement() async {
    await assertErrorsInCode('''
var v = [for (; 0;) 1];
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 16, 1),
    ]);
  }

  test_if() async {
    await assertErrorsInCode(r'''
f() {
  if (3) return 2; else return 1;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 12, 1),
    ]);
  }

  test_ifElement() async {
    await assertErrorsInCode('''
var v = [if (3) 1];
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 13, 1),
    ]);
  }

  test_while() async {
    await assertErrorsInCode(r'''
f() {
  while (3) {}
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 15, 1),
    ]);
  }
}

@reflectiveTest
class NonBoolConditionTest_NNBD extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_if_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  if (x) {}
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 22, 1),
    ]);
  }

  test_ternary_condition_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  x ? 0 : 1;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 18, 1),
    ]);
  }
}
