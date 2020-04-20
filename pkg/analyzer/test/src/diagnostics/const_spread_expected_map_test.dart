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
    defineReflectiveTests(ConstSpreadExpectedMapTest);
    defineReflectiveTests(ConstSpreadExpectedMapWithConstantsTest);
  });
}

@reflectiveTest
class ConstSpreadExpectedMapTest extends DriverResolutionTest {
  test_const_mapInt() async {
    await assertErrorsInCode(
        '''
const dynamic a = 5;
var b = const <int, int>{...a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP, 49, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 46, 4),
              ]);
  }

  test_const_mapList() async {
    await assertErrorsInCode(
        '''
const dynamic a = <int>[5];
var b = const <int, int>{...a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP, 56, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 53, 4),
              ]);
  }

  test_const_mapMap() async {
    await assertNoErrorsInCode('''
const dynamic a = <int, int>{1: 2};
var b = <int, int>{...a};
''');
  }

  test_const_mapNull() async {
    await assertErrorsInCode(
        '''
const dynamic a = null;
var b = const <int, int>{...a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP, 52, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 49, 4),
              ]);
  }

  test_const_mapNull_nullable() async {
    await assertNoErrorsInCode('''
const dynamic a = null;
var b = <int, int>{...?a};
''');
  }

  test_const_mapSet() async {
    await assertErrorsInCode(
        '''
const dynamic a = <int>{5};
var b = const <int, int>{...a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP, 56, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 53, 4),
              ]);
  }

  test_nonConst_mapInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 5;
var b = <int, int>{...a};
''');
  }

  test_nonConst_mapMap() async {
    await assertNoErrorsInCode('''
const dynamic a = {1: 2};
var b = <int, int>{...a};
''');
  }
}

@reflectiveTest
class ConstSpreadExpectedMapWithConstantsTest
    extends ConstSpreadExpectedMapTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );
}
