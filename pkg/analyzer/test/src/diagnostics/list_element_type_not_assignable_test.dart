// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListElementTypeNotAssignableTest);
    defineReflectiveTests(ListElementTypeNotAssignableWithUIAsCodeTest);
  });
}

@reflectiveTest
class ListElementTypeNotAssignableTest extends DriverResolutionTest {
  test_const_stringInt() async {
    await assertErrorsInCode('''
var v = const <String>[42];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_stringInt_dynamic() async {
    await assertErrorsInCode('''
const dynamic x = 42;
var v = const <String>[x];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_stringNull() async {
    await assertNoErrorsInCode('''
var v = const <String>[null];
''');
  }

  test_const_stringNull_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic x = null;
var v = const <String>[x];
''');
  }

  test_const_voidInt() async {
    await assertNoErrorsInCode('''
var v = const <void>[42];
''');
  }

  test_nonConst_stringInt() async {
    await assertErrorsInCode('''
var v = <String>[42];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_stringInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic x = 42;
var v = <String>[x];
''');
  }

  test_nonConst_voidInt() async {
    await assertNoErrorsInCode('''
var v = <void>[42];
''');
  }
}

@reflectiveTest
class ListElementTypeNotAssignableWithUIAsCodeTest
    extends ListElementTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = ['control-flow-collections', 'spread-collections'];

  test_const_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>[if (1 < 0) a else b];
''');
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await assertErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>[if (1 < 0) a else b];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_ifElement_thenFalse_intString() async {
    await assertErrorsInCode('''
var v = const <int>[if (1 < 0) 'a'];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = const <int>[if (1 < 0) a];
''');
  }

  test_const_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int>[if (true) a];
''');
  }

  test_const_ifElement_thenTrue_intString() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int>[if (true) a];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_const_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = const <int>[...[0, 1]];
''');
  }

  test_nonConst_ifElement_thenElseFalse_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
const dynamic b = 'b';
var v = <int>[if (1 < 0) a else b];
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int>[if (1 < 0) a else b];
''');
  }

  test_nonConst_ifElement_thenFalse_intString() async {
    await assertErrorsInCode('''
var v = <int>[if (1 < 0) 'a'];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_nonConst_ifElement_thenTrue_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int>[if (true) a];
''');
  }

  test_nonConst_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int>[if (true) a];
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int>[...[0, 1]];
''');
  }
}
