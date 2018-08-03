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
  test_conflictingGenericInterfaces_simple() =>
      super.test_conflictingGenericInterfaces_simple();

  @override // Passes with driver
  test_conflictingGenericInterfaces_viaMixin() =>
      super.test_conflictingGenericInterfaces_viaMixin();

  @override // Passes with driver
  test_mixinInference_conflictingSubstitution() =>
      super.test_mixinInference_conflictingSubstitution();

  @override // Passes with driver
  test_mixinInference_doNotIgnorePreviousExplicitMixins() =>
      super.test_mixinInference_doNotIgnorePreviousExplicitMixins();

  @override // Passes with driver
  test_mixinInference_impossibleSubstitution() =>
      super.test_mixinInference_impossibleSubstitution();

  @override // Passes with driver
  test_mixinInference_noMatchingClass_constraintSatisfiedByImplementsClause() =>
      super
          .test_mixinInference_noMatchingClass_constraintSatisfiedByImplementsClause();

  @override // Passes with driver
  test_mixinInference_recursiveSubtypeCheck() =>
      super.test_mixinInference_recursiveSubtypeCheck();
}
