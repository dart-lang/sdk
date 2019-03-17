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
    defineReflectiveTests(NotMapSpreadTest);
  });
}

@reflectiveTest
class NotMapSpreadTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_map() async {
    await assertNoErrorsInCode('''
var a = {0: 0};
var v = <int, int>{...a};
''');
  }

  test_map_null() async {
    await assertNoErrorsInCode('''
var v = <int, int>{...?null};
''');
  }

  test_notMap_direct() async {
    await assertErrorsInCode('''
var a = 0;
var v = <int, int>{...a};
''', [CompileTimeErrorCode.NOT_MAP_SPREAD]);
  }

  test_notMap_forElement() async {
    await assertErrorsInCode('''
var a = 0;
var v = <int, int>{for (var i in []) ...a};
''', [CompileTimeErrorCode.NOT_MAP_SPREAD]);
  }

  test_notMap_ifElement_else() async {
    await assertErrorsInCode('''
var a = 0;
var v = <int, int>{if (1 > 0) ...<int, int>{} else ...a};
''', [CompileTimeErrorCode.NOT_MAP_SPREAD]);
  }

  test_notMap_ifElement_then() async {
    await assertErrorsInCode('''
var a = 0;
var v = <int, int>{if (1 > 0) ...a};
''', [CompileTimeErrorCode.NOT_MAP_SPREAD]);
  }
}
