// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionEqEqOperatorTest);
  });
}

@reflectiveTest
class SdkVersionEqEqOperatorTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );

  test_left_equals() async {
    await verifyVersion('2.5.0', '''
class A {
  const A();
}
const A a = A();
const c = a == null;
''');
  }

  test_left_lessThan() async {
    await verifyVersion('2.2.0', '''
class A {
  const A();
}
const A a = A();
const c = a == null;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT, 54, 2),
    ]);
  }

  test_right_equals() async {
    await verifyVersion('2.5.0', '''
class A {
  const A();
}
const A a = A();
const c = null == a;
''');
  }

  test_right_lessThan() async {
    await verifyVersion('2.2.0', '''
class A {
  const A();
}
const A a = A();
const c = null == a;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT, 57, 2),
    ]);
  }
}
