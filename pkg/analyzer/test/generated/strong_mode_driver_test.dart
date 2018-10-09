// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';
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
    extends StaticTypeAnalyzer2TestShared
    with StrongModeStaticTypeAnalyzer2TestCases {
  @override
  bool get enableNewAnalysisDriver => true;

  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    resetWith(options: options);
  }

  @failingTest
  @override
  test_genericFunction_parameter() {
    return super.test_genericFunction_parameter();
  }

  @failingTest
  @override
  test_genericMethod_functionExpressionInvocation_functionTypedParameter_explicit() {
    return super
        .test_genericMethod_functionExpressionInvocation_functionTypedParameter_explicit();
  }

  @failingTest
  @override
  test_genericMethod_functionExpressionInvocation_functionTypedParameter_inferred() {
    return super
        .test_genericMethod_functionExpressionInvocation_functionTypedParameter_inferred();
  }

  @failingTest
  @override
  test_genericMethod_functionInvocation_functionTypedParameter_explicit() {
    return super
        .test_genericMethod_functionInvocation_functionTypedParameter_explicit();
  }

  @failingTest
  @override
  test_genericMethod_functionInvocation_functionTypedParameter_inferred() {
    return super
        .test_genericMethod_functionInvocation_functionTypedParameter_inferred();
  }

  @failingTest
  @override
  test_genericMethod_functionTypedParameter_tearoff() {
    return super.test_genericMethod_functionTypedParameter_tearoff();
  }

  @override
  @failingTest
  test_genericMethod_nestedCaptureBounds() {
    // https://github.com/dart-lang/sdk/issues/30236
    return super.test_genericMethod_nestedCaptureBounds();
  }

  @override
  @failingTest
  test_genericMethod_tearoff_instantiated() {
    return super.test_genericMethod_tearoff_instantiated();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_error_extension_malbounded() {
    return super.test_instantiateToBounds_class_error_extension_malbounded();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_error_instantiation_malbounded() {
    return super
        .test_instantiateToBounds_class_error_instantiation_malbounded();
  }

  @override
  @failingTest
  test_instantiateToBounds_generic_function_error_malbounded() {
    return super.test_instantiateToBounds_generic_function_error_malbounded();
  }
}

@reflectiveTest
class StrongModeTypePropagationTest_Driver
    extends StrongModeTypePropagationTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
