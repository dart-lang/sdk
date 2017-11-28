// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simulates a use of test_progress during a failing run of test.dart.

import "dart:io";
import "../../../tools/testing/dart/test_progress.dart";
import "../../../tools/testing/dart/test_runner.dart";
import "../../../tools/testing/dart/test_options.dart";

main(List<String> arguments) {
  var progressType = arguments[0];
  // Build a progress indicator.
  var startTime = new DateTime.now();
  var progress = new ProgressIndicator.fromName(progressType, startTime, false);
  if (progressType == 'buildbot') {
    BuildbotProgressIndicator.stepName = 'myStepName';
  }
  // Build a dummy test case.
  var configuration = new TestOptionsParser().parse(['--timeout', '2'])[0];
  var dummyCommand = new Command("noop", []);
  var testCase = new TestCase('failing_test.dart', [dummyCommand],
      configuration, (_) => null, new Set<String>.from(['PASS']));

  // Simulate the test.dart use of the progress indicator.
  progress.testAdded();
  progress.allTestsKnown();
  progress.start(testCase);
  new CommandOutput.fromCase(testCase, dummyCommand, 1, false, false, [], [],
      new DateTime.now().difference(startTime), false);
  progress.done(testCase);
  progress.allDone();
}
