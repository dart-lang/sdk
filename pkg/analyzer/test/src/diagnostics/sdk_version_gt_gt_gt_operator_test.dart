// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionGtGtGtOperatorTest);
  });
}

@reflectiveTest
class SdkVersionGtGtGtOperatorTest extends SdkConstraintVerifierTest {
  @override
  String get testPackageLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: [
          EnableString.triple_shift,
        ],
      ),
    );
  }

  test_const_equals() async {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when triple_shift is enabled by default.
    await verifyVersion('2.5.0', '''
const a = 42 >>> 3;
''', expectedErrors: [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 13, 3),
    ]);
  }

  test_const_lessThan() async {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when triple_shift is enabled by default.
    await verifyVersion('2.2.0', '''
const a = 42 >>> 3;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_GT_GT_GT_OPERATOR, 13, 3),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 13, 3),
    ]);
  }

  test_declaration_equals() async {
    await verifyVersion('2.5.0', '''
class A {
  A operator >>>(A a) => this;
}
''');
  }

  test_declaration_lessThan() async {
    await verifyVersion('2.2.0', '''
class A {
  A operator >>>(A a) => this;
}
''', expectedErrors: [
      error(HintCode.SDK_VERSION_GT_GT_GT_OPERATOR, 23, 3),
    ]);
  }

  test_nonConst_equals() async {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when constant update is enabled by default.
    await verifyVersion('2.5.0', '''
var a = 42 >>> 3;
''', expectedErrors: [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 11, 3),
    ]);
  }

  test_nonConst_lessThan() async {
    // TODO(brianwilkerson) Add '>>>' to MockSdk and remove the code
    //  UNDEFINED_OPERATOR when constant update is enabled by default.
    await verifyVersion('2.2.0', '''
var a = 42 >>> 3;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_GT_GT_GT_OPERATOR, 11, 3),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 11, 3),
    ]);
  }
}
