// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantSetElementTest);
    defineReflectiveTests(NonConstantSetElementTest_language24);
  });
}

@reflectiveTest
class NonConstantSetElementTest extends PubPackageResolutionTest
    with NonConstantSetElementTestCases {
  @override
  bool get _constant_update_2018 => true;
}

@reflectiveTest
class NonConstantSetElementTest_language24 extends PubPackageResolutionTest
    with NonConstantSetElementTestCases {
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

mixin NonConstantSetElementTestCases on PubPackageResolutionTest {
  bool get _constant_update_2018;

  test_const_forElement() async {
    await assertErrorsInCode(r'''
const Set set = {};
var v = const {for (final x in set) x};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 35, 22),
    ]);
  }

  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const <int>{if (1 < 0) 0 else a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 59, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 19),
              ]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a else 0};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 52, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 19),
              ]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const <int>{if (1 > 0) 0 else a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 59, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 19),
              ]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a else 0};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 52, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 19),
              ]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
var v = const <int>{if (1 < 0) a};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 12),
              ]);
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const <int>{if (1 < 0) a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 52, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 12),
              ]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
var v = const <int>{if (1 > 0) a};
''',
        _constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 12),
              ]);
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const <int>{if (1 > 0) a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 52, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 12),
              ]);
  }

  test_const_parameter() async {
    await assertErrorsInCode(r'''
f(a) {
  return const {a};
}''', [
      error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 23, 1),
    ]);
  }

  test_const_spread_final() async {
    await assertErrorsInCode(
        r'''
final Set x = null;
var v = const {...x};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 38, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 35, 4),
              ]);
  }

  test_const_topVar() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const <int>{a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 1),
    ]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = <int>{a};
''');
  }
}
