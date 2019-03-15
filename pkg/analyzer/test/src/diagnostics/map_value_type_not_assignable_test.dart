// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapValueTypeNotAssignableTest);
    defineReflectiveTests(MapValueTypeNotAssignableWithUIAsCodeTest);
  });
}

@reflectiveTest
class MapValueTypeNotAssignableTest extends DriverResolutionTest {
  test_const_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <bool, int>{true: a};
''');
  }

  test_const_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <bool, int>{true: a};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_intString_value() async {
    await assertErrorsInCode('''
var v = const <bool, int>{true: 'a'};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <bool, int>{true: a};
''');
  }

  test_nonConst_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <bool, int>{true: a};
''');
  }

  test_nonConst_intString_value() async {
    await assertErrorsInCode('''
var v = <bool, int>{true: 'a'};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }
}

@reflectiveTest
class MapValueTypeNotAssignableWithUIAsCodeTest
    extends MapValueTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = ['control-flow-collections', 'spread-collections'];

  test_const_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_const_ifElement_thenElseFalse_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <bool, int>{if (1 < 0) true: a else false: b};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = const <bool, int>{if (1 < 0) true: a};
''');
  }

  test_const_ifElement_thenFalse_intString_value() async {
    await assertErrorsInCode('''
var v = const <bool, int>{if (1 < 0) true: 'a'};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  @failingTest
  test_const_ifElement_thenFalse_notConst() async {
    await assertErrorsInCode('''
final a = 0;
var v = const <bool, int>{if (1 > 2) true: a};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
  }

  test_const_ifElement_thenTrue_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <bool, int>{if (true) true: a};
''');
  }

  test_const_ifElement_thenTrue_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <bool, int>{if (true) true: a};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_ifElement_thenTrue_notConst() async {
    await assertErrorsInCode('''
final a = 0;
var v = const <bool, int>{if (1 < 2) true: a};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
  }

  test_const_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = const <bool, int>{...{true: 1}};
''');
  }

  test_const_spread_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <bool, int>{...{true: a}};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = <bool, int>{if (1 < 0) true: a else false: b};
''');
  }

  test_nonConst_ifElement_thenFalse_intString_value() async {
    await assertErrorsInCode('''
var v = <bool, int>{if (1 < 0) true: 'a'};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenTrue_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <bool, int>{if (true) true: a};
''');
  }

  test_nonConst_ifElement_thenTrue_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <bool, int>{if (true) true: a};
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <bool, int>{...{true: 1}};
''');
  }

  test_nonConst_spread_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <bool, int>{...{true: a}};
''');
  }
}
