// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverResolutionTest_Kernel);
  });
}

@reflectiveTest
class AnalysisDriverResolutionTest_Kernel extends AnalysisDriverResolutionTest {
  @override
  bool get useCFE => true;

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33795')
  test_annotation_onDirective_partOf() async {
    await super.test_annotation_onDirective_partOf();
  }

  @override
  @failingTest
  test_generic_function_type() async {
    await super.test_generic_function_type();
  }

  @override
  @failingTest
  test_invalid_annotation_on_variable_declaration_for() async {
    await super.test_invalid_annotation_on_variable_declaration_for();
  }

  @override
  @failingTest
  test_invalid_constructor_initializer_field_importPrefix() async {
    await super.test_invalid_constructor_initializer_field_importPrefix();
  }

  @override
  @failingTest
  test_methodInvocation_topLevelFunction_generic() async {
    await super.test_methodInvocation_topLevelFunction_generic();
  }

  @override
  @failingTest
  test_unresolved_assignment_left_indexed1_simple() async {
    await super.test_unresolved_assignment_left_indexed1_simple();
  }

  @override
  @failingTest
  test_unresolved_assignment_left_indexed2_simple() async {
    await super.test_unresolved_assignment_left_indexed2_simple();
  }

  @override
  @failingTest
  test_unresolved_assignment_left_indexed3_simple() async {
    await super.test_unresolved_assignment_left_indexed3_simple();
  }

  @override
  @failingTest
  test_unresolved_assignment_left_indexed4_simple() async {
    await super.test_unresolved_assignment_left_indexed4_simple();
  }

  @override
  @failingTest
  test_unresolved_methodInvocation_target_unresolved() async {
    await super.test_unresolved_methodInvocation_target_unresolved();
  }

  @override
  @failingTest
  test_unresolved_redirectingFactory_22() async {
    await super.test_unresolved_redirectingFactory_22();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
