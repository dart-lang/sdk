// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListElementTypeNotAssignableTest);
    defineReflectiveTests(ListElementTypeNotAssignableTest_language24);
  });
}

@reflectiveTest
class ListElementTypeNotAssignableTest extends PubPackageResolutionTest
    with ListElementTypeNotAssignableTestCases {
  @override
  bool get _constant_update_2018 => true;
}

@reflectiveTest
class ListElementTypeNotAssignableTest_language24
    extends PubPackageResolutionTest
    with ListElementTypeNotAssignableTestCases {
  @override
  bool get _constant_update_2018 => false;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.4',
    );
  }
}

mixin ListElementTypeNotAssignableTestCases on PubPackageResolutionTest {
  bool get _constant_update_2018;

  test_const_ifElement_thenElseFalse_intInt() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>[if (1 < 0) a else b];
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 62, 19),
              ]);
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>[if (1 < 0) a else b];
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 82,
                    1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 64, 19),
              ]);
  }

  test_const_ifElement_thenFalse_intString() async {
    await assertErrorsInCode(
        '''
var v = const <int>[if (1 < 0) 'a'];
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 31,
                    3),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 20, 14),
                error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 31,
                    3),
              ]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 'a';
var v = const <int>[if (1 < 0) a];
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 43, 12),
              ]);
  }

  test_const_ifElement_thenTrue_intInt() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
var v = const <int>[if (true) a];
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 41, 11),
              ]);
  }

  test_const_ifElement_thenTrue_intString() async {
    await assertErrorsInCode(
        '''
const dynamic a = 'a';
var v = const <int>[if (true) a];
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 53,
                    1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 43, 11),
              ]);
  }

  test_const_spread_intInt() async {
    await assertErrorsInCode(
        '''
var v = const <int>[...[0, 1]];
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 20, 9),
              ]);
  }

  test_const_stringInt() async {
    await assertErrorsInCode('''
var v = const <String>[42];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 23, 2),
    ]);
  }

  test_const_stringInt_dynamic() async {
    await assertErrorsInCode('''
const dynamic x = 42;
var v = const <String>[x];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 45, 1),
    ]);
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

  test_element_type_is_assignable() async {
    await assertNoErrorsInCode(r'''
var v1 = <int> [42];
var v2 = const <int> [42];
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
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 25, 3),
    ]);
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

  test_nonConst_stringInt() async {
    await assertErrorsInCode('''
var v = <String>[42];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 17, 2),
    ]);
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
