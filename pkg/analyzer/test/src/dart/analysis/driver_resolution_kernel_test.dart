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

  @failingTest
  @override
  test_annotation_onVariableList_topLevelVariable() =>
      super.test_annotation_onVariableList_topLevelVariable();

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_closure_generic() async {
    // Bad state: Not found T in main() → dynamic
    // https://github.com/dart-lang/sdk/issues/33722
    await super.test_closure_generic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_local_function_generic() async {
    // Bad state: Not found T in main() → void
    // https://github.com/dart-lang/sdk/issues/33722
    await super.test_local_function_generic();
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
  test_unresolved_instanceCreation_name_11() async {
    await super.test_unresolved_instanceCreation_name_11();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_instanceCreation_name_21() async {
    await super.test_unresolved_instanceCreation_name_21();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_instanceCreation_name_22() async {
    await super.test_unresolved_instanceCreation_name_22();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_instanceCreation_name_31() async {
    await super.test_unresolved_instanceCreation_name_31();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_instanceCreation_name_32() async {
    await super.test_unresolved_instanceCreation_name_32();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_instanceCreation_name_33() async {
    await super.test_unresolved_instanceCreation_name_33();
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
  test_unresolved_methodInvocation_target_resolved() async {
    await super.test_unresolved_methodInvocation_target_resolved();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_methodInvocation_target_unresolved() async {
    await super.test_unresolved_methodInvocation_target_unresolved();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_postfix_operand() async {
    // Bad state: No data for a at 11
    await super.test_unresolved_postfix_operand();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_postfix_operator() async {
//    Actual: 'dynamic'
//    Which: is different.
//    Expected: A
    await super.test_unresolved_postfix_operator();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unresolved_prefix_operand() async {
    // Bad state: No data for a at 13
    await super.test_unresolved_prefix_operand();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
