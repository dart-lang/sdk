// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("TestRunnerTest");

#import("../../../tools/testing/dart/test_runner.dart");
#import("../../../tools/testing/dart/status_file_parser.dart");
#source("ProcessTestUtil.dart");

class TestController {
  static final int numTests = 4;
  static int numCompletedTests = 0;

  // Used as TestCase.completedCallback.
  static processCompletedTest(TestCase testCase) {
    TestOutput output = testCase.output;
    print("Test: ${testCase.commandLine}");
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
      print("TestRunnerTest.dart PASSED");
    }
  }
}


TestCase MakeTestCase(String testName, List<String> expectations) {
  String test_path = "tests/standalone/src/${testName}.dart";
  // Working directory may be dart/runtime rather than dart.
  if (!new File(test_path).existsSync()) {
    test_path = "../tests/standalone/src/${testName}.dart";
  }

  var configuration = { 'timeout': 2,
                        'special-command': '' };
  return new TestCase(testName,
                      getDartFileName(),
                      <String>["--ignore-unrecognized-flags",
                               "--enable_type_checks",
                               test_path],
                      configuration,
                      TestController.processCompletedTest,
                      new Set<String>.from(expectations));
}


void main() {
  var configuration = { 'timeout': 2,
                        'special-command': '' };
  new RunningProcess(MakeTestCase("PassTest", [PASS])).start();
  new RunningProcess(MakeTestCase("FailTest", [FAIL])).start();
  new RunningProcess(MakeTestCase("TimeoutTest", [TIMEOUT])).start();

  new RunningProcess(new TestCase("CrashTest",
                                  getProcessTestFileName(),
                                  const ["0", "0", "1", "1"],
                                  configuration,
                                  TestController.processCompletedTest,
                                  new Set<String>.from([CRASH]))).start();
  Expect.equals(4, TestController.numTests);
  // Throw must be from body of start() function for this test to work.
  Expect.throws(new RunningProcess(MakeTestCase("PassTest", [SKIP])).start);
}

