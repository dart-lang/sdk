// Copyright (c) 2
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictModeTest_Kernel);
    defineReflectiveTests(TypePropagationTest_Kernel);
  });
}

@reflectiveTest
class StrictModeTest_Kernel extends StrictModeTest_Driver {
  @override
  bool get enableKernelDriver => true;
}

@reflectiveTest
class TypePropagationTest_Kernel extends TypePropagationTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_assignment_throwExpression() async {
    return super.test_assignment_throwExpression();
  }

  @override
  @failingTest
  test_CanvasElement_getContext() async {
    return super.test_CanvasElement_getContext();
  }

  @override
  @failingTest
  test_initializer_dereference() async {
    return super.test_initializer_dereference();
  }

  @override
  @failingTest
  test_objectMethodInference_disabled_for_library_prefix() async {
    return super.test_objectMethodInference_disabled_for_library_prefix();
  }

  @override
  @failingTest
  test_query() async {
    return super.test_query();
  }
}
