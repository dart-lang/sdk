// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("dart:isolate");
#import("../../../tools/testing/dart/test_runner.dart");
#import("../../../tools/testing/dart/status_file_parser.dart");
#import("../../../tools/testing/dart/test_options.dart");
#source("process_test_util.dart");

class TestController {
  static const int numTests = 4;
  static int numCompletedTests = 0;

  // Used as TestCase.completedCallback.
  static processCompletedTest(TestCase testCase) {
    CommandOutput output = testCase.lastCommandOutput;
    print("Test: ${testCase.commands.last.commandLine}");
    if (output.unexpectedOutput) {
      throw "Unexpected output: ${output.result}";
    }
    print("stdout: ");
    for (var line in output.stdout) print(line);
    print("stderr: ");
    for (var line in output.stderr) print(line);

    print("Time: ${output.time}");
    print("Exit code: ${output.exitCode}");

    ++numCompletedTests;
    print("$numCompletedTests/$numTests");
    if (numCompletedTests == numTests) {
      print("test_runner_test.dart PASSED");
    }
  }
}

TestCase MakeTestCase(String testName, List<String> expectations) {
  var configuration = new TestOptionsParser().parse(['--timeout', '2'])[0];
  return new TestCase(testName,
                      [new Command(new Options().executable,
                                   <String>[new Options().script,
                                            testName])],
                      configuration,
                      TestController.processCompletedTest,
                      new Set<String>.from(expectations));
}

void testTestRunner() {
  new RunningProcess(MakeTestCase("pass", [PASS])).start();
  new RunningProcess(MakeTestCase("fail", [FAIL])).start();
  new RunningProcess(MakeTestCase("timeout", [TIMEOUT])).start();

  // The crash test sometimes times out.  Run it with a large timeout to help
  // diagnose the delay.
  // The test loads a new executable, which may sometimes take a long time.
  // It involves a wait on the VM event loop, and possible system delays.
  var configuration = new TestOptionsParser().parse(['--timeout', '60'])[0];
  new RunningProcess(new TestCase("CrashTest",
                                  [new Command(getProcessTestFileName(),
                                               const ["0", "0", "1", "1"])],
                                  configuration,
                                  TestController.processCompletedTest,
                                  new Set<String>.from([CRASH]))).start();
  Expect.equals(4, TestController.numTests);
  // Test that the test runner throws an exception if a test with
  // expectation SKIP is run.  The RunningProcess constructor must throw
  // the exception synchronously, for it to be caught here at the call site.
  Expect.throws(new RunningProcess(MakeTestCase("pass", [SKIP])).start);
}

void main() {
  // Run the test_runner_test if there are no command-line options.
  // Otherwise, run one of the component tests that always pass,
  // fail, or timeout.
  var arguments = new Options().arguments;
  if (arguments.isEmpty) {
    testTestRunner();
  } else {
    switch (arguments[0]) {
      case 'pass':
        return;
      case 'fail':
        Expect.fail("This test always fails, to test the test scripts.");
	break;
      case 'timeout':
        // Run for 10 seconds, then exit.  This tests a 2 second timeout.
        new Timer(10 * 1000, (t){ });
        break;
      default:
        throw "Unknown option ${arguments[0]} passed to test_runner_test";
    }
  }
}
