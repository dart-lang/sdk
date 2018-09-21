// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_error_resolver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest_Driver);
  });
}

@reflectiveTest
class NonErrorResolverTest_Driver extends NonErrorResolverTestBase {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  @failingTest
  test_constConstructorWithMixinWithField_withoutSuperMixins() {
    return super.test_constConstructorWithMixinWithField_withoutSuperMixins();
  }

  @override
  @failingTest
  test_infer_mixin_with_substitution_functionType_new_syntax() {
    return super.test_infer_mixin_with_substitution_functionType_new_syntax();
  }

  @override
  @failingTest
  test_intLiteralInDoubleContext_const_exact() {
    return super.test_intLiteralInDoubleContext_const_exact();
  }

  @override
  @failingTest
  test_null_callMethod() {
    return super.test_null_callMethod();
  }

  @override
  @failingTest
  test_null_callOperator() {
    return super.test_null_callOperator();
  }
}
