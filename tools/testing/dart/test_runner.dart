// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_runner");

#import("status_file_parser.dart");
#import("test_progress.dart");
#import("test_suite.dart");

/**
 * Classes and methods for executing tests.
 *
 * This module includes:
 * - Managing parallel execution of tests, including timeout checks.
 * - Evaluating the output of each test as pass/fail/crash/timeout.
 */

final int NO_TIMEOUT = 0;


class TestCase {
  String executablePath;
  List<String> arguments;
  int timeout;
  String commandLine;
  String displayName;
  TestOutput output;
  bool isNegative;
  Set<String> expectedOutcomes;
  Function completedHandler;

  TestCase(this.displayName,
           this.executablePath,
           this.arguments,
           this.timeout,
           this.completedHandler,
           this.expectedOutcomes,
           [this.isNegative = false]) {
    if (!isNegative) {
      this.isNegative = displayName.contains("NegativeTest");
    }
    commandLine = executablePath;
    for (var arg in arguments) {
      commandLine += " " + arg;
    }
  }

  void completed() { completedHandler(this); }
}


class TestOutput {
  // The TestCase this is the output from.
  TestCase testCase;
  int exitCode;
  bool timedOut;
  bool failed = false;
  List<String> stdout;
  List<String> stderr;
  Duration time;

  TestOutput(this.testCase, this.exitCode, this.timedOut, this.stdout,
             this.stderr, this.time) {
    testCase.output = this;
  }

  String get result() =>
      hasCrashed ? CRASH : (hasTimedOut ? TIMEOUT : (hasFailed ? FAIL : PASS));

  bool get unexpectedOutput() => !testCase.expectedOutcomes.contains(result);

  // The Java dartc runner exits with code 253 in case of unhandles
  // exceptions.
  // The VM uses std::abort to terminate on asserts.
  // std::abort terminates with exit code 3 on Windows.
  bool get hasCrashed() {
    if (new Platform().operatingSystem() == 'windows') {
      if (exitCode == 3) {
        return !timedOut;
      }
      return (!timedOut &&
              (exitCode != -1) &&
              (exitCode < 0) &&
              ((0x3FFFFF00 & exitCode) == 0));
    }
    return (!timedOut &&
            (exitCode != -1) &&
            ((exitCode < 0) || (exitCode == 253)));
  }

  bool get hasTimedOut() => timedOut;

  bool get didFail() => exitCode != 0 && !hasCrashed;

  // Reverse result of a negative test.
  bool get hasFailed() => (testCase.isNegative ? !didFail : didFail);
}


class RunningProcess {
  Process process;
  TestCase testCase;
  int timeout;
  bool timedOut = false;
  Date startTime;
  Timer timeoutTimer;
  List<String> stdout;
  List<String> stderr;
  List<Function> handlers;

  RunningProcess(this.testCase, [this.timeout = NO_TIMEOUT]);

  void exitHandler(int exitCode) {
    new TestOutput(testCase, exitCode, timedOut, stdout,
                   stderr, new Date.now().difference(startTime));
    process.close();
    timeoutTimer.cancel();
    testCase.completed();
  }

  void makeReadHandler(StringInputStream source, List<String> destination) {
    return () {
      if (source.closed) return;  // TODO(whesse): Remove when bug is fixed.
      var line = source.readLine();
      while (null != line) {
        destination.add(line);
        line = source.readLine();
      }
    };
  }

  void start() {
    Expect.isFalse(testCase.expectedOutcomes.contains(SKIP));
    process = new Process(testCase.executablePath, testCase.arguments);
    process.exitHandler = exitHandler;
    startTime = new Date.now();
    process.start();

    InputStream stdoutStream = process.stdout;
    InputStream stderrStream = process.stderr;
    stdout = new List<String>();
    stderr = new List<String>();
    StringInputStream stdoutStringStream = new StringInputStream(stdoutStream);
    StringInputStream stderrStringStream = new StringInputStream(stderrStream);
    stdoutStringStream.dataHandler =
        makeReadHandler(stdoutStringStream, stdout);
    stderrStringStream.dataHandler =
        makeReadHandler(stderrStringStream, stderr);
    if (timeout != NO_TIMEOUT) {
      timeoutTimer = new Timer(timeoutHandler, 1000 * timeout, false);
    }
  }

  void timeoutHandler(Timer unusedTimer) {
    timedOut = true;
    process.kill();
  }
}


class ProcessQueue {
  int _numProcesses = 0;
  int _activeTestListers = 0;
  final int _maxProcesses;
  Queue<TestCase> _tests;
  ProgressIndicator _progress;

  ProcessQueue(int this._maxProcesses,
               String progress,
               Date start_time)
      : _tests = new Queue<TestCase>(),
        _progress = new ProgressIndicator.fromName(progress, start_time);

  addTestSuite(TestSuite testSuite) {
    _activeTestListers++;
    testSuite.forEachTest(_runTest, _testListerDone);
  }

  _testListerDone() {
    _activeTestListers--;
    _checkDone();
  }

  _checkDone() {
    if (_activeTestListers == 0 && _tests.isEmpty() && _numProcesses == 0) {
      _progress.allDone();
    }
  }

  _runTest(TestCase test) {
    _progress.testAdded();
    _tests.add(test);
    _tryRunTest();
  }

  _tryRunTest() {
    _checkDone();
    if (_numProcesses < _maxProcesses && !_tests.isEmpty()) {
      TestCase test = _tests.removeFirst();
      _progress.start(test);
      Function oldCallback = test.completedHandler;
      Function wrapper = (TestCase test_arg) {
        _numProcesses--;
        _progress.done(test_arg);
        _tryRunTest();
        oldCallback(test_arg);
      };
      test.completedHandler = wrapper;
      new RunningProcess(test, test.timeout).start();
      _numProcesses++;
    }
  }
}
