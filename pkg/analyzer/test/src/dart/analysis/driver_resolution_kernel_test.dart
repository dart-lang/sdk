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
  @potentialAnalyzerProblem
  test_binaryExpression_notEqual() {
    // Bad state: Invalid location: -1
    return super.test_binaryExpression_notEqual();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
