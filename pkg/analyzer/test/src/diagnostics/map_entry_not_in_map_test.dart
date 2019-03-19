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
    defineReflectiveTests(MapEntryNotInMapTest);
    defineReflectiveTests(MapEntryNotInMapWithUiAsCodeTest);
  });
}

@reflectiveTest
class MapEntryNotInMapTest extends DriverResolutionTest {
  test_set() async {
    await assertErrorsInCode('''
var c = <int>{1:2};
''', [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  test_set_const() async {
    await assertErrorsInCode('''
var c = const <int>{1:2};
''', [ParserErrorCode.UNEXPECTED_TOKEN]);
  }
}

@reflectiveTest
class MapEntryNotInMapWithUiAsCodeTest extends MapEntryNotInMapTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_set() async {
    await assertErrorsInCode('''
var c = <int>{1:2};
''', [CompileTimeErrorCode.MAP_ENTRY_NOT_IN_MAP]);
  }

  test_set_const() async {
    await assertErrorsInCode('''
var c = const <int>{1:2};
''', [CompileTimeErrorCode.MAP_ENTRY_NOT_IN_MAP]);
  }
}
