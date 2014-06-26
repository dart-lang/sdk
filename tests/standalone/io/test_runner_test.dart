// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";
import "dart:async";
import "../../../tools/testing/dart/test_runner.dart";
import "../../../tools/testing/dart/test_suite.dart";
import "../../../tools/testing/dart/test_progress.dart" as progress;
import "../../../tools/testing/dart/status_file_parser.dart";
import "../../../tools/testing/dart/test_options.dart";
import "process_test_util.dart";

final DEFAULT_TIMEOUT = 10;
final LONG_TIMEOUT = 30;

class TestController {
  static int numTests = 0;
  static int numCompletedTests = 0;

  // Used as TestCase.completedCallback.
  static processCompletedTest(TestCase testCase) {
    numCompletedTests++;
    if (testCase.displayName == "fail-unexpected") {
      if (!testCase.unexpectedOutput) {
        var stdout =
            new String.fromCharCodes(testCase.lastCommandOutput.stdout);
        var stderr =
            new String.fromCharCodes(testCase.lastCommandOutput.stderr);
        print("stdout = [$stdout]");
        print("stderr = [$stderr]");
        throw "Test case ${testCase.displayName} passed unexpectedly, "
              "result == ${testCase.result}";
      }
    } else {
      if (testCase.unexpectedOutput) {
        var stdout =
            new String.fromCharCodes(testCase.lastCommandOutput.stdout);
        var stderr =
            new String.fromCharCodes(testCase.lastCommandOutput.stderr);
        print("stdout = [$stdout]");
        print("stderr = [$stderr]");
        throw "Test case ${testCase.displayName} failed, "
              "result == ${testCase.result}";
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

    var testCaseCrash = _makeCrashTestCase("crash", [Expectation.CRASH]);
    var testCasePass = _makeNormalTestCase("pass", [Expectation.PASS]);
    var testCaseFail = _makeNormalTestCase("fail", [Expectation.FAIL]);
    var testCaseTimeout = _makeNormalTestCase("timeout", [Expectation.TIMEOUT]);
    var testCaseFailUnexpected =
        _makeNormalTestCase("fail-unexpected", [Expectation.PASS]);

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
    var command = CommandBuilder.instance.getProcessCommand(
        'custom', Platform.executable, [Platform.script.toFilePath(), name],
        {});
    return _makeTestCase(name, DEFAULT_TIMEOUT, command, expectations);
  }

  _makeCrashTestCase(name, expectations) {
    var crashCommand = CommandBuilder.instance.getProcessCommand(
        'custom_crash', getProcessTestFileName(), ["0", "0", "1", "1"],
        {});
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
                        new Set<Expectation>.from(expectations));
  }
}

void testProcessQueue() {
  var maxProcesses = 2;
  var maxBrowserProcesses = maxProcesses;
  var config = new TestOptionsParser().parse(['--nobatch'])[0];
  new ProcessQueue(config, maxProcesses, maxBrowserProcesses,
      new DateTime.now(), [new CustomTestSuite()],
      [new EventListener()], TestController.finished);
}

class EventListener extends progress.EventListener{
  void done(TestCase test) {
    TestController.processCompletedTest(test);
  }
}

void main(List<String> arguments) {
  // Run the test_runner_test if there are no command-line options.
  // Otherwise, run one of the component tests that always pass,
  // fail, or timeout.
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
        // This process should be killed by the test after DEFAULT_TIMEOUT
        new Timer(new Duration(hours: 42), (){ });
        break;
      default:
        throw "Unknown option ${arguments[0]} passed to test_runner_test";
    }
  }
}
