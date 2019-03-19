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
    defineReflectiveTests(NonConstantSetElementTest);
    defineReflectiveTests(NonConstantSetElementWithUiAsCodeTest);
  });
}

@reflectiveTest
class NonConstantSetElementTest extends DriverResolutionTest {
  test_const_topVar() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{a};
''', [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = <int>{a};
''');
  }
}

@reflectiveTest
class NonConstantSetElementWithUiAsCodeTest extends NonConstantSetElementTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{if (1 < 0) 0 else a};
''', [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a else 0};
''', [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{if (1 > 0) 0 else a};
''', [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a else 0};
''', [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int>{if (1 < 0) a};
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a};
''', [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int>{if (1 > 0) a};
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a};
''', [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }
}
