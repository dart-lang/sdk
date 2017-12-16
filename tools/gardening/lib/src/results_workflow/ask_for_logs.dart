// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:gardening/src/results/test_result_helper.dart';

import 'present_failures.dart';
import '../results/result_json_models.dart';
import '../workflow.dart';

class AskForLogs extends WorkflowStep {
  List<TestResult> testResults = [];

  @override
  Future<WorkflowAction> onShow(payload) async {
    // This is the first step, so payload is disregarded.
    if (testResults.isEmpty) {
      askForInputFirstTime();
      // prefetch builders
    } else {
      askForInputOtherTimes();
    }
    return new WaitForInputWorkflowAction();
  }

  @override
  Future<WorkflowAction> input(String input) async {
    // No input entered.
    if (input == null || input.isEmpty && testResults.length == 0) {
      print("ERROR: Needs to add at least one result log.");
      return new Future.value(new WaitForInputWorkflowAction());
    }
    // Navigate to next step.
    if (input == null || input.isEmpty) {
      return new Future.value(
          new NavigateStepWorkflowAction(new PresentFailures(), testResults));
    }
    await getTestResult(input.split(' ')).then((testResult) {
      if (testResult == null) {
        print("ERROR: The input '$input' is invalid.");
      } else {
        testResults.add(testResult);
      }
    });
    print("Add another log or press <Enter> to continue.");
    return new Future.value(new WaitForInputWorkflowAction());
  }

  @override
  Future<bool> onLeave() {
    return new Future.value(false);
  }

  void askForInputFirstTime() {
    print("The tool needs to lookup tests and their expectations to make "
        "suggestions. The more data-points the tool can find, the better it "
        "can report on potential changes to status files.");
    print("");
    print("IMPORTANT: If you experience failures on builders, the tool needs a "
        "dimensionally close passing configuration, to compute a significant "
        "difference. ");
    print("For tests failures discovered locally, a similar configuration with "
        "non-failing tests will often be available, confusing the tool. If you "
        "are only relying on local changes, just add that single log and "
        "continue.");
    print("You can add test results by the following commands:");
    print("<file>                     : for a local result.log file.\n"
        "<uri_to_result_log>        : for direct links to result.logs.\n"
        "<uri_try_bot>              : for links to try bot builders.\n"
        "<commit_number> <patchset> : for links to try bot builders.\n"
        "<builder>                  : for a builder name.\n"
        "<builder> <build>          : for a builder and build number.\n"
        "<builder_group>            : for a builder group.\n");
    print("Input one of the above commands to add a log:");
  }

  void askForInputOtherTimes() {
    print("Add additional logs or write <Enter> to continue.");
  }
}
