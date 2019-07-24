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
    defineReflectiveTests(NonBoolConditionTest);
    defineReflectiveTests(NonBoolConditionWithConstantsTest);
    defineReflectiveTests(NonBoolConditionTest_NNBD);
  });
}

@reflectiveTest
class NonBoolConditionTest extends DriverResolutionTest {
  test_ifElement() async {
    await assertErrorsInCode(
        '''
const c = [if (3) 1];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticTypeWarningCode.NON_BOOL_CONDITION, 15, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 11, 8),
                error(StaticTypeWarningCode.NON_BOOL_CONDITION, 15, 1),
              ]);
  }
}

@reflectiveTest
class NonBoolConditionTest_NNBD extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];
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

@reflectiveTest
class NonBoolConditionWithConstantsTest extends NonBoolConditionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.constant_update_2018];
}
