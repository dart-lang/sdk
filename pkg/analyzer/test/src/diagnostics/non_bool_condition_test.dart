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
//    defineReflectiveTests(NonBoolConditionTest);
    defineReflectiveTests(NonBoolConditionWithUIAsCodeTest);
  });
}

//@reflectiveTest
class NonBoolConditionTest extends DriverResolutionTest {}

@reflectiveTest
class NonBoolConditionWithUIAsCodeTest extends NonBoolConditionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_ifElement() async {
    assertErrorsInCode('''
const c = [if (3) 1];
''', [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }
}
