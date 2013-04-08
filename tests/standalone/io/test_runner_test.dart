// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";
import "dart:async";
import "dart:utf";
import "../../../tools/testing/dart/test_runner.dart";
import "../../../tools/testing/dart/test_suite.dart";
import "../../../tools/testing/dart/status_file_parser.dart";
import "../../../tools/testing/dart/test_options.dart";
import "process_test_util.dart";

final DEFAULT_TIMEOUT = 2;
final LONG_TIMEOUT = 30;

class TestController {
  static int numTests = 0;
  static int numCompletedTests = 0;

  // Used as TestCase.completedCallback.
  static processCompletedTest(TestCase testCase) {
    numCompletedTests++;
    CommandOutput output = testCase.lastCommandOutput;
    if (testCase.displayName == "fail-unexpected") {
      if (!output.unexpectedOutput) {
        throw "Expected fail-unexpected";
      }
    } else {
      if (output.unexpectedOutput) {
        throw "Unexpected fail";
      }
    }
  }

  static void finished() {
    if (numTests != numCompletedTests) {
      throw "bad completion count. "
            "expected: $numTests, actual: $numCompletedTests";
    }
  }
}


class CustomTestSuite extends TestSuite {
  CustomTestSuite() : super({}, "CustomTestSuite");

  void forEachTest(TestCaseEvent onTest, Map testCache, [onDone]) {
    void enqueueTestCase(testCase) {
      TestController.numTests++;
      onTest(testCase);
    }

    var testCaseCrash = _makeCrashTestCase("crash", [CRASH]);
    var testCasePass = _makeNormalTestCase("pass", [PASS]);
    var testCaseFail = _makeNormalTestCase("fail", [FAIL]);
    var testCaseTimeout = _makeNormalTestCase("timeout", [TIMEOUT]);
    var testCaseFailUnexpected =
        _makeNormalTestCase("fail-unexpected", [PASS]);

    enqueueTestCase(testCaseCrash);
    enqueueTestCase(testCasePass);
    enqueueTestCase(testCaseFail);
    enqueueTestCase(testCaseTimeout);
    enqueueTestCase(testCaseFailUnexpected);

    if (onDone != null) {
      onDone();
    }
  }

  TestCase _makeNormalTestCase(name, expectations) {
    var command = new Command(new Options().executable,
                              [new Options().script, name]);
    return _makeTestCase(name, DEFAULT_TIMEOUT, command, expectations);
  }

  _makeCrashTestCase(name, expectations) {
    var crashCommand = new Command(getProcessTestFileName(),
                                   ["0", "0", "1", "1"]);
    // The crash test sometimes times out. Run it with a large timeout
    // to help diagnose the delay.
    // The test loads a new executable, which may sometimes take a long time.
    // It involves a wait on the VM event loop, and possible system
    // delays.
    return _makeTestCase(name, LONG_TIMEOUT, crashCommand, expectations);
  }

  _makeTestCase(name, timeout, command, expectations) {
    var configuration = new TestOptionsParser()
        .parse(['--timeout', '$timeout'])[0];
    return new TestCase(name,
                        [command],
                        configuration,
                        TestController.processCompletedTest,
                        new Set<String>.from(expectations));
  }
}

void testProcessQueue() {
  var maxProcesses = 2;
  var maxBrowserProcesses = maxProcesses;
  new ProcessQueue(maxProcesses, maxBrowserProcesses,
      new DateTime.now(), [new CustomTestSuite()], [], TestController.finished);
}

void main() {
  // Run the test_runner_test if there are no command-line options.
  // Otherwise, run one of the component tests that always pass,
  // fail, or timeout.
  var arguments = new Options().arguments;
  if (arguments.isEmpty) {
    testProcessQueue();
  } else {
    switch (arguments[0]) {
      case 'pass':
        return;
      case 'fail-unexpected':
      case 'fail':
        throw "This test always fails, to test the test scripts.";
        break;
      case 'timeout':
        // Run for 10 seconds, then exit.  This tests a 2 second timeout.
        new Timer(new Duration(seconds: 10), (){ });
        break;
      default:
        throw "Unknown option ${arguments[0]} passed to test_runner_test";
    }
  }
}
