// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'strong_mode_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeLocalInferenceTest_Kernel);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test_Kernel);
    defineReflectiveTests(StrongModeTypePropagationTest_Kernel);
  });
}

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class StrongModeLocalInferenceTest_Kernel extends StrongModeLocalInferenceTest {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get enableNewAnalysisDriver => true;

  @override
  @failingTest
  test_async_star_method_propagation() async {
    return super.test_async_star_method_propagation();
  }

  @override
  @failingTest
  test_async_star_propagation() async {
    return super.test_async_star_propagation();
  }

  @override
  @failingTest
  test_covarianceChecks_returnFunction() async {
    return super.test_covarianceChecks_returnFunction();
  }

  @override
  @failingTest
  test_generic_partial() async {
    return super.test_generic_partial();
  }

  @override
  @failingTest
  test_instanceCreation() async {
    return super.test_instanceCreation();
  }

  @override
  @failingTest
  test_redirectingConstructor_propagation() async {
    return super.test_redirectingConstructor_propagation();
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
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31059')
  test_genericMethod_functionExpressionInvocation_explicit() async {
    return super.test_genericMethod_functionExpressionInvocation_explicit();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_error_recursion() async {
    return super.test_instantiateToBounds_class_error_recursion();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_error_recursion_self() async {
    return super.test_instantiateToBounds_class_error_recursion_self();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_error_recursion_self2() async {
    return super.test_instantiateToBounds_class_error_recursion_self2();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_error_typedef() async {
    return super.test_instantiateToBounds_class_error_typedef();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_ok_implicitDynamic_multi() async {
    return super.test_instantiateToBounds_class_ok_implicitDynamic_multi();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_ok_referenceOther_after() async {
    return super.test_instantiateToBounds_class_ok_referenceOther_after();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_ok_referenceOther_after2() async {
    return super.test_instantiateToBounds_class_ok_referenceOther_after2();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_ok_referenceOther_before() async {
    return super.test_instantiateToBounds_class_ok_referenceOther_before();
  }

  @override
  @failingTest
  test_instantiateToBounds_class_ok_referenceOther_multi() async {
    return super.test_instantiateToBounds_class_ok_referenceOther_multi();
  }
}

@reflectiveTest
class StrongModeTypePropagationTest_Kernel
    extends StrongModeTypePropagationTest {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get enableNewAnalysisDriver => true;
}
