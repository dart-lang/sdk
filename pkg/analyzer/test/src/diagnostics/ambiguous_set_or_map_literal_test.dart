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
    defineReflectiveTests(AmbiguousSetOrMapLiteralBothTest);
    defineReflectiveTests(AmbiguousSetOrMapLiteralEitherTest);
  });
}

@reflectiveTest
class AmbiguousSetOrMapLiteralBothTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  test_setAndMap() async {
    assertErrorsInCode('''
Map<int, int> map;
Set<int> set;
var c = {...set, ...map};
''', [CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH]);
  }
}

@reflectiveTest
class AmbiguousSetOrMapLiteralEitherTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  test_setAndMap() async {
    assertErrorsInCode('''
var map;
var set;
var c = {...set, ...map};
''', [CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER]);
  }
}
