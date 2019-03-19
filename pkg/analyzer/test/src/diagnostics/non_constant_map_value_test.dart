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
    defineReflectiveTests(NonConstantMapValueTest);
    defineReflectiveTests(NonConstantMapValueWithUiAsCodeTest);
  });
}

@reflectiveTest
class NonConstantMapValueTest extends DriverResolutionTest {
  test_const_topLevel() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
var v = const {'a' : a};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
  }
}

@reflectiveTest
class NonConstantMapValueWithUiAsCodeTest extends NonConstantMapValueTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  test_const_ifTrue_elseFinal() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a': 'b', 'c' : a};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
  }

  test_const_ifTrue_thenFinal() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a' : a};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
  }
}
