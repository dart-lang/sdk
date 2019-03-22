// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionGtGtGtOperatorTest);
  });
}

@reflectiveTest
class SdkVersionGtGtGtOperatorTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.constant_update_2018];

  test_const_equals() {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when constant update is enabled by default.
    verifyVersion('2.2.2', '''
const a = 42 >>> 3;
''', errorCodes: [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_const_lessThan() {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when constant update is enabled by default.
    verifyVersion('2.2.0', '''
const a = 42 >>> 3;
''', errorCodes: [
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
      HintCode.SDK_VERSION_GT_GT_GT_OPERATOR
    ]);
  }

  test_declaration_equals() {
    verifyVersion('2.2.2', '''
class A {
  A operator >>>(A a) => this;
}
''');
  }

  test_declaration_lessThan() {
    verifyVersion('2.2.0', '''
class A {
  A operator >>>(A a) => this;
}
''', errorCodes: [HintCode.SDK_VERSION_GT_GT_GT_OPERATOR]);
  }

  test_nonConst_equals() {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when constant update is enabled by default.
    verifyVersion('2.2.2', '''
var a = 42 >>> 3;
''', errorCodes: [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_nonConst_lessThan() {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when constant update is enabled by default.
    verifyVersion('2.2.0', '''
var a = 42 >>> 3;
''', errorCodes: [
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
      HintCode.SDK_VERSION_GT_GT_GT_OPERATOR
    ]);
  }
}
