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
    defineReflectiveTests(NonBoolOperandTest_NNBD);
  });
}

@reflectiveTest
class NonBoolOperandTest_NNBD extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_and_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  if(x && true) {}
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 21, 1),
    ]);
  }

  test_or_null() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  if(x || false) {}
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 21, 1),
    ]);
  }
}
