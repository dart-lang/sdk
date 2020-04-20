// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetElementTypeNotAssignableTest);
    defineReflectiveTests(SetElementTypeNotAssignableWithConstantTest);
  });
}

@reflectiveTest
class SetElementTypeNotAssignableTest extends DriverResolutionTest {
  test_const_ifElement_thenElseFalse_intInt() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>{if (1 < 0) a else b};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 62, 19),
              ]);
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>{if (1 < 0) a else b};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 82, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 64, 19),
              ]);
  }

  test_const_ifElement_thenFalse_intString() async {
    await assertErrorsInCode(
        '''
var v = const <int>{if (1 < 0) 'a'};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 31, 3),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 20, 14),
                error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 31, 3),
              ]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 'a';
var v = const <int>{if (1 < 0) a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 43, 12),
              ]);
  }

  test_const_ifElement_thenTrue_intInt() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
var v = const <int>{if (true) a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 41, 11),
              ]);
  }

  test_const_ifElement_thenTrue_intString() async {
    await assertErrorsInCode(
        '''
const dynamic a = 'a';
var v = const <int>{if (true) a};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 53, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 43, 11),
              ]);
  }

  test_const_spread_intInt() async {
    await assertErrorsInCode(
        '''
var v = const <int>{...[0, 1]};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT, 20, 9),
              ]);
  }

  test_explicitTypeArgs_const() async {
    await assertErrorsInCode('''
var v = const <String>{42};
''', [
      error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 23, 2),
    ]);
  }

  test_explicitTypeArgs_const_actualTypeMatch() async {
    await assertNoErrorsInCode('''
const dynamic x = null;
var v = const <String>{x};
''');
  }

  test_explicitTypeArgs_const_actualTypeMismatch() async {
    await assertErrorsInCode('''
const dynamic x = 42;
var v = const <String>{x};
''', [
      error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 45, 1),
    ]);
  }

  test_explicitTypeArgs_notConst() async {
    await assertErrorsInCode('''
var v = <String>{42};
''', [
      error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 17, 2),
    ]);
  }

  test_nonConst_ifElement_thenElseFalse_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
const dynamic b = 'b';
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenFalse_intString() async {
    await assertErrorsInCode('''
var v = <int>[if (1 < 0) 'a'];
''', [
      error(StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 25, 3),
    ]);
  }

  test_nonConst_ifElement_thenTrue_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int>{if (true) a};
''');
  }

  test_nonConst_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int>{if (true) a};
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int>{...[0, 1]};
''');
  }
}

@reflectiveTest
class SetElementTypeNotAssignableWithConstantTest
    extends SetElementTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );
}
