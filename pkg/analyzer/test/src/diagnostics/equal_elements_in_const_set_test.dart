// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualElementsInConstSetTest);
    defineReflectiveTests(EqualElementsInConstSetTest_language24);
  });
}

@reflectiveTest
class EqualElementsInConstSetTest extends PubPackageResolutionTest
    with EqualElementsInConstSetTestCases {
  @override
  bool get _constant_update_2018 => true;
}

@reflectiveTest
class EqualElementsInConstSetTest_language24 extends PubPackageResolutionTest
    with EqualElementsInConstSetTestCases {
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

mixin EqualElementsInConstSetTestCases on PubPackageResolutionTest {
  bool get _constant_update_2018;

  test_const_entry() async {
    await assertErrorsInCode('''
var c = const {1, 2, 1};
''', [
      error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 21, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 15, 1)]),
    ]);
  }

  test_const_ifElement_thenElseFalse() async {
    await assertErrorsInCode(
        '''
var c = const {1, if (1 < 0) 2 else 1};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 36, 1,
                    contextMessages: [
                      message('$testPackageLibPath/test.dart', 15, 1)
                    ]),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 18, 19),
              ]);
  }

  test_const_ifElement_thenElseFalse_onlyElse() async {
    await assertErrorsInCode(
        '''
var c = const {if (0 < 1) 1 else 1};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 15, 19),
              ]);
  }

  test_const_ifElement_thenElseTrue() async {
    await assertErrorsInCode(
        '''
var c = const {1, if (0 < 1) 2 else 1};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 18, 19),
              ]);
  }

  test_const_ifElement_thenElseTrue_onlyThen() async {
    await assertErrorsInCode(
        '''
var c = const {if (0 < 1) 1 else 1};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 15, 19),
              ]);
  }

  test_const_ifElement_thenFalse() async {
    await assertErrorsInCode(
        '''
var c = const {2, if (1 < 0) 2};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 18, 12),
              ]);
  }

  test_const_ifElement_thenTrue() async {
    await assertErrorsInCode(
        '''
var c = const {1, if (0 < 1) 1};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 29, 1,
                    contextMessages: [
                      message('$testPackageLibPath/test.dart', 15, 1)
                    ]),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 18, 12),
              ]);
  }

  test_const_instanceCreation_equalTypeArgs() async {
    await assertErrorsInCode(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(), const A<int>()};
''', [
      error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 60, 14,
          contextMessages: [message('$testPackageLibPath/test.dart', 44, 14)]),
    ]);
  }

  test_const_instanceCreation_notEqualTypeArgs() async {
    // No error because A<int> and A<num> are different types.
    await assertNoErrorsInCode(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(), const A<num>()};
''');
  }

  test_const_spread__noDuplicate() async {
    await assertErrorsInCode(
        '''
var c = const {1, ...{2}};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 18, 6),
              ]);
  }

  test_const_spread_hasDuplicate() async {
    await assertErrorsInCode(
        '''
var c = const {1, ...{1}};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, 21, 3,
                    contextMessages: [
                      message('$testPackageLibPath/test.dart', 15, 1)
                    ]),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 18, 6),
              ]);
  }

  test_nonConst_entry() async {
    // No error, but there is a hint.
    await assertErrorsInCode('''
var c = {1, 2, 1};
''', [
      error(HintCode.EQUAL_ELEMENTS_IN_SET, 15, 1),
    ]);
  }
}
