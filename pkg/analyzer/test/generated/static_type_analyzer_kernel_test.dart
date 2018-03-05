// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_type_analyzer_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(scheglov): Restore similar test coverage when the front-end API
    // allows it.  See https://github.com/dart-lang/sdk/issues/32258.
    // defineReflectiveTests(StaticTypeAnalyzer2Test_Kernel);
  });
}

@reflectiveTest
class StaticTypeAnalyzer2Test_Kernel extends StaticTypeAnalyzer2Test_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  @failingTest
  test_FunctionExpressionInvocation_block() async {
    // Bad state: No reference information for (() {return 1;})() at 21
    await super.test_FunctionExpressionInvocation_block();
  }

  @override
  @failingTest
  test_MethodInvocation_nameType_parameter_propagatedType() async {
    // Expected: DynamicTypeImpl:<dynamic>
    await super.test_MethodInvocation_nameType_parameter_propagatedType();
  }

  @override
  @failingTest
  test_staticMethods_classTypeParameters_genericMethod() async {
    // Expected: '(dynamic) → void'
    await super.test_staticMethods_classTypeParameters_genericMethod();
  }
}
