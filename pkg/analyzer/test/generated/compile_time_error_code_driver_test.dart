// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'compile_time_error_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest_Driver);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest_Driver extends CompileTimeErrorCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @override // Passes with driver
  test_mixinInference_doNotIgnorePreviousExplicitMixins() =>
      super.test_mixinInference_doNotIgnorePreviousExplicitMixins();

  @override // Passes with driver
  test_mixinInference_matchingClass() =>
      super.test_mixinInference_matchingClass();

  @override // Passes with driver
  test_mixinInference_matchingClass_inPreviousMixin() =>
      super.test_mixinInference_matchingClass_inPreviousMixin();

  @override // Passes with driver
  test_mixinInference_recursiveSubtypeCheck() =>
      super.test_mixinInference_recursiveSubtypeCheck();
}
