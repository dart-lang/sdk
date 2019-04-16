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
    defineReflectiveTests(EqualKeysInConstMapTest);
    defineReflectiveTests(EqualKeysInConstMapWithUIAsCodeAndConstantsTest);
    defineReflectiveTests(EqualKeysInConstMapWithUIAsCodeTest);
  });
}

@reflectiveTest
class EqualKeysInConstMapTest extends DriverResolutionTest {
  test_const_entry() async {
    await assertErrorCodesInCode('''
var c = const {1: null, 2: null, 1: null};
''', [CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP]);
  }

  test_const_instanceCreation_equalTypeArgs() async {
    await assertErrorCodesInCode(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(): null, const A<int>(): null};
''', [CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP]);
  }

  test_const_instanceCreation_notEqualTypeArgs() async {
    // No error because A<int> and A<num> are different types.
    await assertNoErrorsInCode(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(): null, const A<num>(): null};
''');
  }

  test_nonConst_entry() async {
    await assertNoErrorsInCode('''
var c = {1: null, 2: null, 1: null};
''');
  }
}

@reflectiveTest
class EqualKeysInConstMapWithUIAsCodeAndConstantsTest
    extends EqualKeysInConstMapWithUIAsCodeTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
      EnableString.constant_update_2018
    ];
}

@reflectiveTest
class EqualKeysInConstMapWithUIAsCodeTest extends EqualKeysInConstMapTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_const_ifElement_thenElseFalse() async {
    await assertErrorCodesInCode(
        '''
var c = const {1: null, if (1 < 0) 2: null else 1: null};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_onlyElse() async {
    assertErrorCodesInCode(
        '''
var c = const {if (0 < 1) 1: null else 1: null};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue() async {
    assertErrorCodesInCode(
        '''
var c = const {1: null, if (0 < 1) 2: null else 1: null};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_onlyThen() async {
    assertErrorCodesInCode(
        '''
var c = const {if (0 < 1) 1: null else 1: null};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenFalse() async {
    assertErrorCodesInCode(
        '''
var c = const {2: null, if (1 < 0) 2: 2};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_ifElement_thenTrue() async {
    await assertErrorCodesInCode(
        '''
var c = const {1: null, if (0 < 1) 1: null};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_spread__noDuplicate() async {
    await assertErrorCodesInCode(
        '''
var c = const {1: null, ...{2: null}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }

  test_const_spread_hasDuplicate() async {
    await assertErrorCodesInCode(
        '''
var c = const {1: null, ...{1: null}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP]
            : [CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT]);
  }
}
