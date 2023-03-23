// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:status_file/expectation.dart";
import "package:test_runner/src/command.dart";
import "package:test_runner/src/configuration.dart";
import "package:test_runner/src/options.dart";
import 'package:test_runner/src/path.dart';
import "package:test_runner/src/process_queue.dart";
import "package:test_runner/src/repository.dart";
import "package:test_runner/src/test_case.dart";
import 'package:test_runner/src/test_file.dart';
import "package:test_runner/src/test_progress.dart" as progress;
import "package:test_runner/src/test_suite.dart";

final defaultTimeout = 10;

List<String> packageOptions() {
  if (Platform.packageConfig != null) {
    return <String>['--packages=${Platform.packageConfig}'];
  } else {
    return <String>[];
  }
}

class TestController {
  static int numTests = 0;
  static int numCompletedTests = 0;

  // Used as TestCase.completedCallback.
  static processCompletedTest(TestCase testCase) {
    numCompletedTests++;
    if (testCase.displayName == "fail-unexpected") {
      if (!testCase.unexpectedOutput) {
        var stdout = String.fromCharCodes(testCase.lastCommandOutput.stdout);
        var stderr = String.fromCharCodes(testCase.lastCommandOutput.stderr);
        print("stdout = [$stdout]");
        print("stderr = [$stderr]");
        throw "Test case ${testCase.displayName} passed unexpectedly, "
            "result == ${testCase.result}";
      }
    } else {
      if (testCase.unexpectedOutput) {
        var stdout = String.fromCharCodes(testCase.lastCommandOutput.stdout);
        var stderr = String.fromCharCodes(testCase.lastCommandOutput.stderr);
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
  CustomTestSuite(TestConfiguration configuration)
      : super(configuration, "CustomTestSuite", []);

  @override
  void findTestCases(TestCaseEvent onTest, Map testCache) {
    void enqueueTestCase(TestCase testCase) {
      TestController.numTests++;
      onTest(testCase);
    }

    var testCaseCrash = _makeNormalTestCase("crash", [Expectation.crash]);
    var testCasePass = _makeNormalTestCase("pass", [Expectation.pass]);
    var testCaseFail = _makeNormalTestCase("fail", [Expectation.fail]);
    var testCaseTimeout = _makeNormalTestCase("timeout", [Expectation.timeout]);
    var testCaseFailUnexpected =
        _makeNormalTestCase("fail-unexpected", [Expectation.pass]);

    enqueueTestCase(testCaseCrash);
    enqueueTestCase(testCasePass);
    enqueueTestCase(testCaseFail);
    enqueueTestCase(testCaseTimeout);
    enqueueTestCase(testCaseFailUnexpected);
  }

  TestCase _makeNormalTestCase(
      String name, Iterable<Expectation> expectations) {
    var args = packageOptions();
    args.addAll([Platform.script.toFilePath(), name]);
    var command = ProcessCommand('custom', Platform.executable, args, {});
    return _makeTestCase(name, defaultTimeout, command, expectations);
  }

  TestCase _makeTestCase(String name, timeout, Command command,
      Iterable<Expectation> expectations) {
    var configuration = OptionsParser().parse(['--timeout', '$timeout'])[0];
    return TestCase(
        name,
        [command],
        configuration,
        Set<Expectation>.from(expectations),
        TestFile.parse(Path('suite'), '/dummy_test.dart', ''));
  }
}

void testProcessQueue() {
  var maxProcesses = 2;
  var maxBrowserProcesses = maxProcesses;
  var config = OptionsParser().parse(['--no-batch'])[0];
  ProcessQueue(config, maxProcesses, maxBrowserProcesses,
      [CustomTestSuite(config)], [EventListener()], TestController.finished);
}

class EventListener extends progress.EventListener {
  @override
  void done(TestCase test) {
    TestController.processCompletedTest(test);
  }
}

void main(List<String> arguments) {
  // This script is in [sdk]/tests/standalone/io.
  Repository.uri = Platform.script.resolve('../../..');
  // Run the test_runner_test if there are no command-line options.
  // Otherwise, run one of the component tests that always pass,
  // fail, or timeout.
  if (arguments.isEmpty) {
    testProcessQueue();
  } else {
    switch (arguments[0]) {
      case 'crash':
        exit(253);
      case 'fail-unexpected':
      case 'fail':
        throw "This test always fails, to test the test scripts.";
      case 'pass':
        return;
      case 'timeout':
        // This process should be killed by the test after DEFAULT_TIMEOUT
        Timer(const Duration(hours: 42), () {});
        break;
      default:
        throw "Unknown option ${arguments[0]} passed to test_runner_test";
    }
  }
}
