// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapKeyTypeNotAssignableTest);
    defineReflectiveTests(MapKeyTypeNotAssignableWithUIAsCodeTest);
  });
}

@reflectiveTest
class MapKeyTypeNotAssignableTest extends DriverResolutionTest {
  test_const_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, bool>{a : true};
''');
  }

  test_const_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int, bool>{a : true};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_intString_value() async {
    await assertErrorsInCode('''
var v = const <int, bool>{'a' : true};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int, bool>{a : true};
''');
  }

  test_nonConst_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int, bool>{a : true};
''');
  }

  test_nonConst_intString_value() async {
    await assertErrorsInCode('''
var v = <int, bool>{'a' : true};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }
}

@reflectiveTest
class MapKeyTypeNotAssignableWithUIAsCodeTest
    extends MapKeyTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = ['control-flow-collections', 'spread-collections'];

  test_const_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_const_ifElement_thenElseFalse_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int, bool>{if (1 < 0) a: true else b: false};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = const <int, bool>{if (1 < 0) a: true};
''');
  }

  test_const_ifElement_thenFalse_intString_value() async {
    await assertErrorsInCode('''
var v = const <int, bool>{if (1 < 0) 'a': true};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }

  @failingTest
  test_const_ifElement_thenFalse_notConst() async {
    await assertErrorsInCode('''
final a = 0;
var v = const <int, bool>{if (1 > 2) a: true};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]);
  }

  test_const_ifElement_thenTrue_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, bool>{if (true) a: true};
''');
  }

  test_const_ifElement_thenTrue_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int, bool>{if (true) a: true};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_ifElement_thenTrue_notConst() async {
    await assertErrorsInCode('''
final a = 0;
var v = const <int, bool>{if (1 < 2) a: true};
''', [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]);
  }

  test_const_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = const <int, String>{...{1: 'a'}};
''');
  }

  test_const_spread_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int, String>{...{a: 'a'}};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_nonConst_ifElement_thenFalse_intString_value() async {
    await assertErrorsInCode('''
var v = <int, bool>{if (1 < 0) 'a': true};
''', [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenTrue_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int, bool>{if (true) a: true};
''');
  }

  test_nonConst_ifElement_thenTrue_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int, bool>{if (true) a: true};
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int, String>{...{1: 'a'}};
''');
  }

  test_nonConst_spread_intString_dynamic() async {
    await assertNoErrorsInCode('''
dynamic a = 'a';
var v = <int, String>{...{a: 'a'}};
''');
  }
}
