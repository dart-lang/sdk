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
    defineReflectiveTests(NonConstantMapValueTest);
    defineReflectiveTests(NonConstantMapValueWithConstantsTest);
  });
}

@reflectiveTest
class NonConstantMapValueTest extends DriverResolutionTest {
  test_const_ifTrue_elseFinal() async {
    await assertErrorsInCode(
        r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a': 'b', 'c' : a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 81, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 55, 18),
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 81, 1),
              ]);
  }

  test_const_ifTrue_thenFinal() async {
    await assertErrorsInCode(
        r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a' : a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 71, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 55, 17),
              ]);
  }

  test_const_topLevel() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
var v = const {'a' : a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 42, 1),
    ]);
  }
}

@reflectiveTest
class NonConstantMapValueWithConstantsTest extends NonConstantMapValueTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );
}
