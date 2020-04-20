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
    defineReflectiveTests(NonConstantListElementTest);
    defineReflectiveTests(NonConstantListElementWithConstantsTest);
  });
}

@reflectiveTest
class NonConstantListElementTest extends DriverResolutionTest {
  test_const_forElement() async {
    await assertErrorsInCode(r'''
const Set set = {};
var v = const [for(final x in set) x];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 35, 21),
    ]);
  }

  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const [if (1 < 0) 0 else a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 54, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 19),
              ]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const [if (1 < 0) a else 0];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 19),
              ]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const [if (1 > 0) 0 else a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 54, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 19),
              ]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const [if (1 > 0) a else 0];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 19),
              ]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
var v = const [if (1 < 0) a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 12),
              ]);
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const [if (1 < 0) a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 12),
              ]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertErrorsInCode(
        '''
const dynamic a = 0;
var v = const [if (1 > 0) a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 12),
              ]);
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorsInCode(
        '''
final dynamic a = 0;
var v = const [if (1 > 0) a];
''',
        analysisOptions.experimentStatus.constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 12),
              ]);
  }

  test_const_topVar() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [a];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 1),
    ]);
  }

  test_const_topVar_nested() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
var v = const [a + 1];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 1),
    ]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = [a];
''');
  }
}

@reflectiveTest
class NonConstantListElementWithConstantsTest
    extends NonConstantListElementTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );
}
