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

  test_ifElement_elseBranch_evaluated_addsDuplicate() async {
    await assertErrorsInCode('''
void main() {
  const notTrue = false;
  const {1: null, if (notTrue) 2: null else 1: null};
}
''', [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
  }

  test_ifElement_evaluated_addsDuplicate() async {
    await assertErrorsInCode('''
void main() {
  const {1: null, if (true) 1: null};
}
''', [StaticWarningCode.EQUAL_KEYS_IN_MAP]);
  }

  @failingTest
  test_ifElement_notEvaluated_doesntAddDuplicate() async {
    await assertNoErrorsInCode('''
void main() {
  const notTrue = false;
  const {1: null, if (notTrue) 1: null};
}
''');
  }

  @failingTest
  test_ifElement_withElse_evaluated_doesntAddDuplicate() async {
    await assertNoErrorsInCode('''
void main() {
  const isTrue = true;
  const {if (isTrue) 1: null : 1 :null};
}
''');
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
