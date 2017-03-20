// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'strong_mode_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeLocalInferenceTest_Driver);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test_Driver);
    defineReflectiveTests(StrongModeTypePropagationTest_Driver);
  });
}

@reflectiveTest
class StrongModeLocalInferenceTest_Driver extends StrongModeLocalInferenceTest {
  @override
  bool get enableNewAnalysisDriver => true;
}

@reflectiveTest
class StrongModeStaticTypeAnalyzer2Test_Driver
    extends StrongModeStaticTypeAnalyzer2Test {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  test_genericFunction_parameter() {
    return super.test_genericFunction_parameter();
  }

  @failingTest
  @override
  test_genericMethod_functionExpressionInvocation_explicit() {
    return super.test_genericMethod_functionExpressionInvocation_explicit();
  }

  @failingTest
  @override
  test_genericMethod_functionExpressionInvocation_inferred() {
    return super.test_genericMethod_functionExpressionInvocation_inferred();
  }

  @failingTest
  @override
  test_genericMethod_functionInvocation_explicit() {
    return super.test_genericMethod_functionInvocation_explicit();
  }

  @failingTest
  @override
  test_genericMethod_functionInvocation_inferred() {
    return super.test_genericMethod_functionInvocation_inferred();
  }

  @failingTest
  @override
  test_genericMethod_tearoff() {
    return super.test_genericMethod_tearoff();
  }
}

@reflectiveTest
class StrongModeTypePropagationTest_Driver
    extends StrongModeTypePropagationTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
