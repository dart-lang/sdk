// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'strong_mode_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrongModeLocalInferenceTest_Kernel);
    defineReflectiveTests(StrongModeStaticTypeAnalyzer2Test_Kernel);
    defineReflectiveTests(StrongModeTypePropagationTest_Kernel);
  });
}

@reflectiveTest
class StrongModeLocalInferenceTest_Kernel
    extends StrongModeLocalInferenceTest_Driver {
  @override
  bool get enableKernelDriver => true;

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
  test_factoryConstructor_propagation() async {
    return super.test_factoryConstructor_propagation();
  }

  @override
  @failingTest
  test_futureOr_assignFromFuture() async {
    return super.test_futureOr_assignFromFuture();
  }

  @override
  @failingTest
  test_futureOr_downwards1() async {
    return super.test_futureOr_downwards1();
  }

  @override
  @failingTest
  test_futureOr_downwards2() async {
    return super.test_futureOr_downwards2();
  }

  @override
  @failingTest
  test_futureOr_downwards3() async {
    return super.test_futureOr_downwards3();
  }

  @override
  @failingTest
  test_futureOr_downwards4() async {
    return super.test_futureOr_downwards4();
  }

  @override
  @failingTest
  test_futureOr_downwards5() async {
    return super.test_futureOr_downwards5();
  }

  @override
  @failingTest
  test_futureOr_downwards6() async {
    return super.test_futureOr_downwards6();
  }

  @override
  @failingTest
  test_futureOr_downwards7() async {
    return super.test_futureOr_downwards7();
  }

  @override
  @failingTest
  test_futureOr_downwards8() async {
    return super.test_futureOr_downwards8();
  }

  @override
  @failingTest
  test_futureOr_no_return() async {
    return super.test_futureOr_no_return();
  }

  @override
  @failingTest
  test_futureOr_no_return_value() async {
    return super.test_futureOr_no_return_value();
  }

  @override
  @failingTest
  test_futureOr_return_null() async {
    return super.test_futureOr_return_null();
  }

  @override
  @failingTest
  test_futureOr_upwards1() async {
    return super.test_futureOr_upwards1();
  }

  @override
  @failingTest
  test_futureOr_upwards2() async {
    return super.test_futureOr_upwards2();
  }

  @override
  @failingTest
  test_futureOrNull_no_return() async {
    return super.test_futureOrNull_no_return();
  }

  @override
  @failingTest
  test_futureOrNull_no_return_value() async {
    return super.test_futureOrNull_no_return_value();
  }

  @override
  @failingTest
  test_futureOrNull_return_null() async {
    return super.test_futureOrNull_return_null();
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
    extends StrongModeStaticTypeAnalyzer2Test_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_genericMethod_then() async {
    return super.test_genericMethod_then();
  }

  @override
  @failingTest
  test_genericMethod_then_prefixed() async {
    return super.test_genericMethod_then_prefixed();
  }

  @override
  @failingTest
  test_genericMethod_then_propagatedType() async {
    return super.test_genericMethod_then_propagatedType();
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

  @override
  @failingTest
  test_notInstantiatedBound_functionType() async {
    return super.test_notInstantiatedBound_functionType();
  }
}

@reflectiveTest
class StrongModeTypePropagationTest_Kernel
    extends StrongModeTypePropagationTest_Driver {
  @override
  bool get enableKernelDriver => true;
}
