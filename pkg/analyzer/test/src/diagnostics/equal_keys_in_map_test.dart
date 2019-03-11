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
    defineReflectiveTests(EqualKeysInMapWithUiAsCodeTest);
  });
}

@reflectiveTest
class EqualKeysInMapWithUiAsCodeTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_ifElement_false_elseEvaluated() async {
    await assertErrorsInCode('''
const c = {1: null, if (1 < 0) 2: null else 1: null};
''', [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
  }

  test_ifElement_false_onlyElseEvaluated() async {
    assertNoErrorsInCode('''
const c = {if (0 < 1) 1 : 1 else 1 : 2};
''');
  }

  test_ifElement_false_thenNotEvaluated() async {
    assertNoErrorsInCode('''
const c = {2 : 1, if (1 < 0) 2 : 2};
''');
  }

  test_ifElement_true_elseNotEvaluated() async {
    assertNoErrorsInCode('''
const c = {1 : 1, if (0 < 1) 2 : 2 else 1 : 2};
''');
  }

  test_ifElement_true_onlyThenEvaluated() async {
    assertNoErrorsInCode('''
const c = {if (0 < 1) 1 : 1 else 1 : 2};
''');
  }

  test_ifElement_true_thenEvaluated() async {
    await assertErrorsInCode('''
const c = {1: null, if (0 < 1) 1: null};
''', [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
  }

  @failingTest
  test_nonConst_noDuplicateReported() async {
    await assertNoErrorsInCode('''
void main() {
  print({1: null, 1: null});
}
''');
  }

  @failingTest
  test_spreadElement_addsDuplicate() async {
    await assertErrorsInCode('''
void main() {
  const {1: null, ...{1: null}};
}
''', [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
  }

  test_spreadElement_doesntAddDuplicate() async {
    await assertNoErrorsInCode('''
void main() {
  const {1: null, ...{2: null}};
}
''');
  }
}
