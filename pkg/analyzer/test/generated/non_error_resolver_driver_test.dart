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
class NonErrorResolverTest_Driver extends NonErrorResolverTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @override // Passes with driver
  test_infer_mixin() => super.test_infer_mixin();

  @override // Passes with driver
  test_infer_mixin_multiplyConstrained() =>
      super.test_infer_mixin_multiplyConstrained();

  @override // Passes with driver
  test_infer_mixin_with_substitution() =>
      super.test_infer_mixin_with_substitution();

  @override // Passes with driver
  test_infer_mixin_with_substitution_functionType() =>
      super.test_infer_mixin_with_substitution_functionType();

  @override // Passes with driver
  test_issue_32394() => super.test_issue_32394();
}
