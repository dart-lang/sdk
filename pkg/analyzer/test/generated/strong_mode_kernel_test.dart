// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'strong_mode_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeLocalInferenceTest_Kernel);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test_Kernel);
    defineReflectiveTests(StrongModeTypePropagationTest_Kernel);
  });
}

@reflectiveTest
class StrongModeLocalInferenceTest_Kernel extends StrongModeLocalInferenceTest {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get enableNewAnalysisDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  test_constrainedByBounds2() async {
    await super.test_constrainedByBounds2();
  }

  @override
  @failingTest
  test_constrainedByBounds3() async {
    await super.test_constrainedByBounds3();
  }

  @override
  @failingTest
  test_constrainedByBounds5() async {
    await super.test_constrainedByBounds5();
  }

  @override
  @failingTest
  test_covarianceChecks() async {
    await super.test_covarianceChecks();
  }

  @override
  @failingTest
  test_covarianceChecks_genericMethods() async {
    await super.test_covarianceChecks_genericMethods();
  }

  @override
  @failingTest
  test_covarianceChecks_returnFunction() async {
    await super.test_covarianceChecks_returnFunction();
  }

  @override
  @failingTest
  test_covarianceChecks_superclass() async {
    await super.test_covarianceChecks_superclass();
  }

  @override
  @failingTest
  test_futureOr_downwards8() async {
    await super.test_futureOr_downwards8();
  }

  @override
  @failingTest
  test_futureOr_methods2() async {
    await super.test_futureOr_methods2();
  }

  @override
  @failingTest
  test_futureOr_methods3() async {
    await super.test_futureOr_methods3();
  }

  @override
  @failingTest
  test_futureOr_methods4() async {
    await super.test_futureOr_methods4();
  }

  @override
  @failingTest
  test_futureOr_no_return() async {
    await super.test_futureOr_no_return();
  }

  @override
  @failingTest
  test_futureOr_no_return_value() async {
    await super.test_futureOr_no_return_value();
  }

  @override
  @failingTest
  test_futureOr_return_null() async {
    await super.test_futureOr_return_null();
  }

  @override
  @failingTest
  test_futureOr_upwards2() async {
    await super.test_futureOr_upwards2();
  }

  @override
  @failingTest
  test_generic_partial() async {
    await super.test_generic_partial();
    // TODO(brianwilkerson) This test periodically fails (by not throwing an
    // exception), so I am temporarily disabling it. The cause of the flaky
    // behavior needs to be investigated.
    fail('Flaky test');
  }

  @override
  @failingTest
  test_inference_error_arguments() async {
    await super.test_inference_error_arguments();
  }

  @override
  @failingTest
  test_inference_error_arguments2() async {
    await super.test_inference_error_arguments2();
  }

  @override
  @failingTest
  test_inference_error_extendsFromReturn() async {
    await super.test_inference_error_extendsFromReturn();
  }

  @override
  @failingTest
  test_inference_error_extendsFromReturn2() async {
    await super.test_inference_error_extendsFromReturn2();
  }

  @override
  @failingTest
  test_inference_error_genericFunction() async {
    await super.test_inference_error_genericFunction();
  }

  @override
  @failingTest
  test_inference_error_returnContext() async {
    await super.test_inference_error_returnContext();
  }

  @override
  @failingTest
  test_inferGenericInstantiation2() async {
    await super.test_inferGenericInstantiation2();
  }

  @override
  @failingTest
  test_instanceCreation() async {
    await super.test_instanceCreation();
    // TODO(brianwilkerson) This test fails as expected when run as part of a
    // larger group of tests, but does not fail when run individually (such as
    // on the bots).
    fail('Flaky test');
  }

  @override
  @failingTest
  test_pinning_multipleConstraints1() async {
    await super.test_pinning_multipleConstraints1();
  }

  @override
  @failingTest
  test_pinning_multipleConstraints3() async {
    await super.test_pinning_multipleConstraints3();
  }

  @override
  @failingTest
  test_redirectedConstructor_named() {
    return super.test_redirectedConstructor_named();
  }

  @override
  @failingTest
  test_redirectedConstructor_unnamed() {
    return super.test_redirectedConstructor_unnamed();
  }

  @override
  @failingTest
  test_redirectingConstructor_propagation() async {
    await super.test_redirectingConstructor_propagation();
    // TODO(brianwilkerson) Figure out why this test is flaky.
    fail('Flaky test');
  }
}

@reflectiveTest
class StrongModeStaticTypeAnalyzer2Test_Kernel
    extends StrongModeStaticTypeAnalyzer2Test {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get enableNewAnalysisDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  test_genericFunction_parameter() async {
    await super.test_genericFunction_parameter();
  }

  @override
  @failingTest
  test_genericMethod_explicitTypeParams() async {
    await super.test_genericMethod_explicitTypeParams();
  }

  @override
  @failingTest
  test_genericMethod_functionExpressionInvocation_explicit() async {
    await super.test_genericMethod_functionExpressionInvocation_explicit();
  }

  @override
  @failingTest
  test_genericMethod_functionExpressionInvocation_functionTypedParameter_explicit() {
    return super
        .test_genericMethod_functionExpressionInvocation_functionTypedParameter_explicit();
  }

  @override
  @failingTest
  test_genericMethod_functionExpressionInvocation_functionTypedParameter_inferred() {
    return super
        .test_genericMethod_functionExpressionInvocation_functionTypedParameter_inferred();
  }

  @override
  @failingTest
  test_genericMethod_functionExpressionInvocation_inferred() async {
    await super.test_genericMethod_functionExpressionInvocation_inferred();
  }

  @override
  @failingTest
  test_genericMethod_functionInvocation_explicit() async {
    await super.test_genericMethod_functionInvocation_explicit();
  }

  @override
  @failingTest
  test_genericMethod_functionInvocation_functionTypedParameter_explicit() {
    return super
        .test_genericMethod_functionInvocation_functionTypedParameter_explicit();
  }

  @override
  @failingTest
  test_genericMethod_functionInvocation_functionTypedParameter_inferred() {
    return super
        .test_genericMethod_functionInvocation_functionTypedParameter_inferred();
  }

  @override
  @failingTest
  test_genericMethod_functionInvocation_inferred() async {
    await super.test_genericMethod_functionInvocation_inferred();
  }

  @override
  @failingTest
  test_genericMethod_functionTypedParameter_tearoff() {
    return super.test_genericMethod_functionTypedParameter_tearoff();
  }

  @override
  @failingTest
  test_genericMethod_implicitDynamic() async {
    await super.test_genericMethod_implicitDynamic();
  }

  @override
  @failingTest
  test_genericMethod_nestedCapture() async {
    await super.test_genericMethod_nestedCapture();
  }

  @override
  @failingTest
  test_genericMethod_partiallyAppliedErrorWithBound() async {
    await super.test_genericMethod_partiallyAppliedErrorWithBound();
  }

  @override
  @failingTest
  test_genericMethod_tearoff() async {
    await super.test_genericMethod_tearoff();
  }

  @override
  @failingTest
  test_genericMethod_toplevel_field_staticTearoff() {
    return super.test_genericMethod_toplevel_field_staticTearoff();
  }

  @override
  test_notInstantiatedBound_class_error_recursion_less_direct() async {
    return super.test_notInstantiatedBound_class_error_recursion_less_direct();
  }

  @override
  @failingTest
  test_notInstantiatedBound_class_error_recursion_typedef() {
    return super.test_notInstantiatedBound_class_error_recursion_typedef();
  }

  @override
  @failingTest
  test_setterWithDynamicTypeIsError() async {
    await super.test_setterWithDynamicTypeIsError();
  }

  @override
  @failingTest
  test_setterWithOtherTypeIsError() async {
    await super.test_setterWithOtherTypeIsError();
  }
}

@reflectiveTest
class StrongModeTypePropagationTest_Kernel
    extends StrongModeTypePropagationTest {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get enableNewAnalysisDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;
}
