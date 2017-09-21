// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_type_warning_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeWarningCodeTest_Kernel);
    defineReflectiveTests(StrongModeStaticTypeWarningCodeTest_Kernel);
  });
}

@reflectiveTest
class StaticTypeWarningCodeTest_Kernel
    extends StaticTypeWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_invalidAssignment_defaultValue_named() async {
    return super.test_invalidAssignment_defaultValue_named();
  }

  @override
  @failingTest
  test_invalidAssignment_defaultValue_optional() async {
    return super.test_invalidAssignment_defaultValue_optional();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_redirectingConstructor() async {
    return super.test_typeArgumentNotMatchingBounds_redirectingConstructor();
  }

  @override
  @failingTest
  test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle() async {
    return super.test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle();
  }

  @override
  @failingTest
  test_undefinedGetter_wrongNumberOfTypeArguments_tooMany() async {
    return super.test_undefinedGetter_wrongNumberOfTypeArguments_tooMany();
  }

  @override
  @failingTest
  test_undefinedMethodWithConstructor() async {
    return super.test_undefinedMethodWithConstructor();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_tooFew() async {
    return super.test_wrongNumberOfTypeArguments_tooFew();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_tooMany() async {
    return super.test_wrongNumberOfTypeArguments_tooMany();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_typeTest_tooFew() async {
    return super.test_wrongNumberOfTypeArguments_typeTest_tooFew();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_typeTest_tooMany() async {
    return super.test_wrongNumberOfTypeArguments_typeTest_tooMany();
  }
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest_Kernel
    extends StrongModeStaticTypeWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;
}
