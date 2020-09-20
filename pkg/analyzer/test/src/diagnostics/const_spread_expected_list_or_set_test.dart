// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstSpreadExpectedListOrSetTest);
    defineReflectiveTests(ConstSpreadExpectedListOrSetTest_language24);
  });
}

@reflectiveTest
class ConstSpreadExpectedListOrSetTest extends PubPackageResolutionTest
    with ConstSpreadExpectedListOrSetTestCases {
  @override
  bool get _constant_update_2018 => true;
}

@reflectiveTest
class ConstSpreadExpectedListOrSetTest_language24
    extends PubPackageResolutionTest
    with ConstSpreadExpectedListOrSetTestCases {
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

mixin ConstSpreadExpectedListOrSetTestCases on PubPackageResolutionTest {
  bool get _constant_update_2018;

  test_const_listInt() async {
    await assertErrorsInCode(
        '''
const dynamic a = 5;
var b = const <int>[...a];
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
                    44, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 41, 4),
              ]);
  }

  test_const_listList() async {
    await assertErrorsInCode(
        '''
const dynamic a = [5];
var b = const <int>[...a];
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 43, 4),
              ]);
  }

  test_const_listMap() async {
    await assertErrorsInCode(
        '''
const dynamic a = <int, int>{0: 1};
var b = const <int>[...a];
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
                    59, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 56, 4),
              ]);
  }

  test_const_listNull() async {
    await assertErrorsInCode(
        '''
const dynamic a = null;
var b = const <int>[...a];
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
                    47, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 44, 4),
              ]);
  }

  test_const_listNull_nullable() async {
    await assertErrorsInCode(
        '''
const dynamic a = null;
var b = const <int>[...?a];
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 44, 5),
              ]);
  }

  test_const_listSet() async {
    await assertErrorsInCode(
        '''
const dynamic a = <int>{5};
var b = const <int>[...a];
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 48, 4),
              ]);
  }

  test_const_setInt() async {
    await assertErrorsInCode(
        '''
const dynamic a = 5;
var b = const <int>{...a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
                    44, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 4),
              ]);
  }

  test_const_setList() async {
    await assertErrorsInCode(
        '''
const dynamic a = <int>[5];
var b = const <int>{...a};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 48, 4),
              ]);
  }

  test_const_setMap() async {
    await assertErrorsInCode(
        '''
const dynamic a = <int, int>{1: 2};
var b = const <int>{...a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
                    59, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 56, 4),
              ]);
  }

  test_const_setNull() async {
    await assertErrorsInCode(
        '''
const dynamic a = null;
var b = const <int>{...a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET,
                    47, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 44, 4),
              ]);
  }

  test_const_setNull_nullable() async {
    await assertErrorsInCode(
        '''
const dynamic a = null;
var b = const <int>{...?a};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 44, 5),
              ]);
  }

  test_const_setSet() async {
    await assertErrorsInCode(
        '''
const dynamic a = <int>{5};
var b = const <int>{...a};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 48, 4),
              ]);
  }

  test_nonConst_listInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 5;
var b = <int>[...a];
''');
  }

  test_nonConst_setInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 5;
var b = <int>{...a};
''');
  }
}
