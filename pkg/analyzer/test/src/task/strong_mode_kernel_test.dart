// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'strong_mode_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberInferrerTest_Driver2);
  });
}

@reflectiveTest
class InstanceMemberInferrerTest_Driver2
    extends InstanceMemberInferrerTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_inferCompilationUnit_method_parameter_multiple_named_same() async {
    return super
        .test_inferCompilationUnit_method_parameter_multiple_named_same();
  }

  @override
  @failingTest
  test_inferCompilationUnit_method_parameter_multiple_optionalAndRequired() async {
    return super
        .test_inferCompilationUnit_method_parameter_multiple_optionalAndRequired();
  }

  @override
  @failingTest
  test_inferCompilationUnit_method_parameter_single_generic() async {
    return super.test_inferCompilationUnit_method_parameter_single_generic();
  }

  @override
  @failingTest
  test_inferCompilationUnit_method_return_multiple_same_generic() async {
    return super
        .test_inferCompilationUnit_method_return_multiple_same_generic();
  }

  @override
  @failingTest
  test_inferCompilationUnit_method_return_multiple_same_nonVoid() async {
    return super
        .test_inferCompilationUnit_method_return_multiple_same_nonVoid();
  }

  @override
  @failingTest
  test_inferCompilationUnit_method_return_multiple_same_void() async {
    return super.test_inferCompilationUnit_method_return_multiple_same_void();
  }

  @override
  @failingTest
  test_inferCompilationUnit_method_return_single() async {
    return super.test_inferCompilationUnit_method_return_single();
  }

  @override
  @failingTest
  test_inferCompilationUnit_method_return_single_generic() async {
    return super.test_inferCompilationUnit_method_return_single_generic();
  }
}
