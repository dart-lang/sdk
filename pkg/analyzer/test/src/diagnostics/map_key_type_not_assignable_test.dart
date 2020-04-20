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
    defineReflectiveTests(MapKeyTypeNotAssignableTest);
    defineReflectiveTests(MapKeyTypeNotAssignableWithConstantsTest);
  });
}

@reflectiveTest
class MapKeyTypeNotAssignableTest extends DriverResolutionTest {
  test_const_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int, bool>{if (1 < 0) a: true else b: false};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 68, 32),
              ]);
  }

  test_const_ifElement_thenElseFalse_intString_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int, bool>{if (1 < 0) a: true else b: false};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 94, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 70, 32),
              ]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 'a';
var v = const <int, bool>{if (1 < 0) a: true};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 49, 18),
              ]);
  }

  test_const_ifElement_thenFalse_intString_value() async {
    await assertErrorsInCode(
        '''
var v = const <int, bool>{if (1 < 0) 'a': true};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 37, 3),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 26, 20),
                error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 37, 3),
              ]);
  }

  test_const_ifElement_thenTrue_intInt_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
var v = const <int, bool>{if (true) a: true};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 47, 17),
              ]);
  }

  test_const_ifElement_thenTrue_intString_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 'a';
var v = const <int, bool>{if (true) a: true};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 59, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 49, 17),
              ]);
  }

  test_const_ifElement_thenTrue_notConst() async {
    await assertErrorsInCode(
        '''
final a = 0;
var v = const <int, bool>{if (1 < 2) a: true};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 50, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 39, 18),
              ]);
  }

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
''', [
      error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 49, 1),
    ]);
  }

  test_const_intString_value() async {
    await assertErrorsInCode('''
var v = const <int, bool>{'a' : true};
''', [
      error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 26, 3),
    ]);
  }

  test_const_spread_intInt() async {
    await assertErrorsInCode(
        '''
var v = const <int, String>{...{1: 'a'}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 28, 11),
              ]);
  }

  test_const_spread_intString_dynamic() async {
    await assertErrorsInCode(
        '''
const dynamic a = 'a';
var v = const <int, String>{...{a: 'a'}};
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 55, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 51, 11),
                error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 55, 1),
              ]);
  }

  test_key_type_is_assignable() async {
    await assertNoErrorsInCode('''
var v = <String, int > {'a' : 1};
''');
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
''', [
      error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 31, 3),
    ]);
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
''', [
      error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 20, 3),
    ]);
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int, String>{...{1: 'a'}};
''');
  }

  test_nonConst_spread_intNum() async {
    await assertNoErrorsInCode('''
var v = <int, int>{...<num, num>{1: 1}};
''');
  }

  test_nonConst_spread_intString() async {
    await assertErrorsInCode('''
var v = <int, String>{...{'a': 'a'}};
''', [
      error(StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 26, 3),
    ]);
  }

  test_nonConst_spread_intString_dynamic() async {
    await assertNoErrorsInCode('''
dynamic a = 'a';
var v = <int, String>{...{a: 'a'}};
''');
  }
}

@reflectiveTest
class MapKeyTypeNotAssignableWithConstantsTest
    extends MapKeyTypeNotAssignableTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );
}
