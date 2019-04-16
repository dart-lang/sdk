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
    defineReflectiveTests(EqualElementsInConstSetTest);
    defineReflectiveTests(EqualElementsInConstSetWithUIAsCodeAndConstantsTest);
    defineReflectiveTests(EqualElementsInConstSetWithUIAsCodeTest);
  });
}

@reflectiveTest
class EqualElementsInConstSetTest extends DriverResolutionTest {
  test_const_entry() async {
    await assertErrorCodesInCode('''
var c = const {1, 2, 1};
''', [CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET]);
  }

  test_const_instanceCreation_equalTypeArgs() async {
    await assertErrorCodesInCode(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(), const A<int>()};
''', [CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET]);
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

  test_nonConst_entry() async {
    await assertNoErrorsInCode('''
var c = {1, 2, 1};
''');
  }
}

@reflectiveTest
class EqualElementsInConstSetWithUIAsCodeAndConstantsTest
    extends EqualElementsInConstSetWithUIAsCodeTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
      EnableString.constant_update_2018
    ];
}

@reflectiveTest
class EqualElementsInConstSetWithUIAsCodeTest
    extends EqualElementsInConstSetTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_const_ifElement_thenElseFalse() async {
    await assertErrorCodesInCode(
        '''
var c = const {1, if (1 < 0) 2 else 1};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET]
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenElseFalse_onlyElse() async {
    assertErrorCodesInCode(
        '''
var c = const {if (0 < 1) 1 else 1};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue() async {
    assertErrorCodesInCode(
        '''
var c = const {1, if (0 < 1) 2 else 1};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenElseTrue_onlyThen() async {
    assertErrorCodesInCode(
        '''
var c = const {if (0 < 1) 1 else 1};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenFalse() async {
    assertErrorCodesInCode(
        '''
var c = const {2, if (1 < 0) 2};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_ifElement_thenTrue() async {
    await assertErrorCodesInCode(
        '''
var c = const {1, if (0 < 1) 1};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET]
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_spread__noDuplicate() async {
    await assertErrorCodesInCode(
        '''
var c = const {1, ...{2}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }

  test_const_spread_hasDuplicate() async {
    await assertErrorCodesInCode(
        '''
var c = const {1, ...{1}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET]
            : [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
  }
}
