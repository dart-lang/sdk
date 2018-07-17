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

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

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
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33800')
  test_annotation_onFormalParameter_redirectingFactory() async {
    await super.test_annotation_onFormalParameter_redirectingFactory();
  }

  @override
  @failingTest
  test_closure_generic() {
    // Assertion error: 'element != null': is not true.
    return super.test_closure_generic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33858')
  test_invalid_fieldInitializer_this() async {
    await super.test_invalid_fieldInitializer_this();
  }

  @override
  @failingTest
  test_local_type_parameter_reference_function_named_parameter_type() {
    // Stack overflow
    return super
        .test_local_type_parameter_reference_function_named_parameter_type();
  }

  @override
  @failingTest
  test_local_type_parameter_reference_function_normal_parameter_type() {
    // Stack overflow
    return super
        .test_local_type_parameter_reference_function_normal_parameter_type();
  }

  @override
  @failingTest
  test_local_type_parameter_reference_function_optional_parameter_type() {
    // Stack overflow
    return super
        .test_local_type_parameter_reference_function_optional_parameter_type();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_assignment_left_indexed1_simple() async {
    await super.test_unresolved_assignment_left_indexed1_simple();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_assignment_left_indexed2_simple() async {
    await super.test_unresolved_assignment_left_indexed2_simple();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_assignment_left_indexed3_simple() async {
    await super.test_unresolved_assignment_left_indexed3_simple();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_assignment_left_indexed4_simple() async {
    await super.test_unresolved_assignment_left_indexed4_simple();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_methodInvocation_noTarget() async {
    await super.test_unresolved_methodInvocation_noTarget();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_methodInvocation_target_unresolved() async {
    await super.test_unresolved_methodInvocation_target_unresolved();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
