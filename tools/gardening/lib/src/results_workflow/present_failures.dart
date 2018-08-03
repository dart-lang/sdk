// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'fix_failing_test.dart';
import '../results/result_json_models.dart';
import '../results/status_expectations.dart';
import '../results/failing_test.dart';
import '../workflow.dart';

class PresentFailures extends WorkflowStep {
  PresentFailures();

  TestResult testResult;
  List<FailingTest> failingTests;

  @override
  Future<WorkflowAction> onShow(payload) async {
    testResult =
        (payload as List<TestResult>).reduce((t1, t2) => t1..combineWith([t2]));

    failingTests = await groupFailingTests(testResult);

    if (failingTests.isEmpty) {
      print("No errors found.. Do you want to add more logs? (y)es or (n)o.");
      return new WaitForInputWorkflowAction();
    } else {
      print("Found ${failingTests.length} status failures. If this number "
          "seems weird or you find tests that seems to pass, check if your "
          "branch is up to date.");
      print("");
      print("It can take some time navigating from tests to tests, since we "
          "modify status files for each fix and have to reload them again.");
      return new Future.value(new NavigateStepWorkflowAction(
          new FixFailingTest(testResult), failingTests));
    }
  }

  @override
  Future<WorkflowAction> input(String input) async {
    if (input == "y") {
      return new BackWorkflowAction();
    }
    return null;
  }

  @override
  Future<bool> onLeave() {
    return new Future.value(false);
  }
}

/// Every failing test is converted to a [FailingTest] to allow grouping passing
/// and failing configurations.
Future<List<FailingTest>> groupFailingTests(TestResult testResult) async {
  var statusExpectations = new StatusExpectations(testResult);
  await statusExpectations.loadStatusFiles();
  List<TestExpectationResult> results =
      statusExpectations.getTestResultsWithExpectation();

  List<TestExpectationResult> failing =
      results.where((x) => !x.isSuccess()).toList();

  // We group failing by their name and their new outcome.
  var grouped = <String, List<FailingTest>>{};

  // Add all failing tests configurations first.
  for (var test in failing) {
    var key = "${test.result.name}";
    var failingTests = grouped.putIfAbsent(key, () => []);
    var failingTest = failingTests.firstWhere(
        (ft) => ft.result.result == test.result.result,
        orElse: () => null);
    if (failingTest == null) {
      failingTest = new FailingTest(test.result, testResult, [], []);
      failingTests.add(failingTest);
    }
    failingTest.failingConfigurations.add(test.configuration);
  }

  // Then add all other configurations, to tighten the bound on the failing
  // configurations.
  for (var result in results) {
    if (result.isSuccess() && grouped.containsKey(result.result.name)) {
      grouped[result.result.name].forEach((failingTest) =>
          failingTest.passingConfigurations.add(result.configuration));
    }
  }

  return grouped.values.expand((failingTests) => failingTests).toList()
    ..sort((a, b) => a.result.name.compareTo(b.result.name));
}
