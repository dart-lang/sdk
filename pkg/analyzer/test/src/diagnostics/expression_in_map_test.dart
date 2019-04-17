// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionInMapTest);
    defineReflectiveTests(ExpressionInMapWithUiAsCodeTest);
  });
}

@reflectiveTest
class ExpressionInMapTest extends DriverResolutionTest {
  bool get isUiAsCode => analysisOptions.experimentStatus.spread_collections;

  test_map() async {
    await assertErrorsInCode(
      '''
var m = <String, int>{'a', 'b' : 2};
''',
      isUiAsCode
          ? [
              error(CompileTimeErrorCode.EXPRESSION_IN_MAP, 22, 3),
            ]
          : [
              error(ParserErrorCode.EXPECTED_TOKEN, 25, 1),
              error(ParserErrorCode.MISSING_IDENTIFIER, 25, 1),
            ],
    );
  }

  test_map_const() async {
    await assertErrorsInCode(
      '''
var m = <String, int>{'a', 'b' : 2};
''',
      isUiAsCode
          ? [
              error(CompileTimeErrorCode.EXPRESSION_IN_MAP, 22, 3),
            ]
          : [
              error(ParserErrorCode.EXPECTED_TOKEN, 25, 1),
              error(ParserErrorCode.MISSING_IDENTIFIER, 25, 1),
            ],
    );
  }
}

@reflectiveTest
class ExpressionInMapWithUiAsCodeTest extends ExpressionInMapTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_map() async {
    await assertErrorsInCode('''
var m = <String, int>{'a', 'b' : 2};
''', [
      error(CompileTimeErrorCode.EXPRESSION_IN_MAP, 22, 3),
    ]);
  }

  test_map_const() async {
    await assertErrorsInCode('''
const m = <String, int>{'a', 'b' : 2};
''', [
      error(CompileTimeErrorCode.EXPRESSION_IN_MAP, 24, 3),
    ]);
  }
}
