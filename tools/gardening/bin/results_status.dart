// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:gardening/src/luci.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/workflow/workflow.dart';

/// Class [StatusCommand] handles the 'status' subcommand and updates status
/// files.
class StatusCommand extends Command {
  @override
  String get description => "Update status files, from failure data and "
      "existing status entries.";

  @override
  String get name => "status";

  Future run() async {
    var workflow = new Workflow();
    return workflow.start(new AskForLogs());
  }
}

Future<models.TestResult> getTestResults(String input) {
  return new Future.value(new models.TestResult());
}

class AskForLogs extends WorkflowStep {
  List<Future<models.TestResult>> futureTestResults = new List<Future>();

  @override
  Future<WorkflowAction> input(String input) {
    // No input entered.
    if (input == null || input.isEmpty && futureTestResults.length == 0) {
      print("ERROR: Needs to add at least one result log.");
      return new Future.value(new WaitForInputWorkflowAction());
    }
    // Navigate to next step.
    if (input == null || input.isEmpty) {
      return new Future.value(new NavigateStepWorkflowAction(
          new ComputeStep(),
          new ComputeStepPayload(Future.wait(futureTestResults),
              "The tool is fetching result logs...", new PresentFailures())));
    }

    // Otherwise, add fetch results via future and return input to the user.
    var newFutureTestResult = getTestResults(input);
    if (newFutureTestResult == null) {
      print("ERROR: The input '$input' is invalid.");
    } else {
      print("The tool is acquiring the logs from the input. Add another log or "
          "<Enter> to continue.");
      futureTestResults.add(newFutureTestResult);
    }
    return new Future.value(new WaitForInputWorkflowAction());
  }

  @override
  Future<bool> onLeave() {
    return new Future.value(false);
  }

  @override
  Future<WorkflowAction> onShow(payload) async {
    // This is the first step, so payload is disregarded.
    if (futureTestResults.length == 0) {
      askForInputFirstTime();
      // prefetch builders
    } else {
      askForInputOtherTimes();
    }
    return new WaitForInputWorkflowAction();
  }

  void askForInputFirstTime() {
    print("The tool needs to lookup tests and their expectations to make "
        "suggestions. The more data-points the tool can find, the better it "
        "can report on potential changes to status files.");
    print("You can add test results by the following commands:");
    print("\t<uri>                   : Either a relative file path, url to a "
        "try builder or url to result log.");
    print("\t<builder-group>         : The builder-group name.");
    print("\t<builder-name>          : Name of the builder.");
    print("\t<builder-name> <number> : Name and build number for a builder.");
    print("\tall <commit>            : All bots for a commit (slow)");
    print("\t<number> <patchset>     : The commit number and patchset "
        "for a CL.");
    print("");
    print("Input one of the above commands to add a log:");
  }

  void askForInputOtherTimes() {
    print("Add additional logs or write <Enter> to continue.");
  }
}

class PresentFailures extends WorkflowStep<List<models.TestResult>> {
  @override
  Future<WorkflowAction> input(String input) {
    if (input == "back") {
      return new Future.value(new BackWorkflowAction());
    }
    return new Future.value(null);
  }

  @override
  Future<bool> onLeave() {
    return new Future.value(false);
  }

  @override
  Future<WorkflowAction> onShow(List<models.TestResult> payload) {
    print("The tool has observed that the following tests have failed. The "
        "tests are grouped by their resulting expectation and all failing "
        "configurations are shown below.");
    print("If you would like to go back and add more result logs, type the "
        "'back' command.");
    print(payload.length);
    return new Future.value(new WaitForInputWorkflowAction());
  }
}
