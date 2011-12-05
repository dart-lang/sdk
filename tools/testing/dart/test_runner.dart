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
  bool timedOut = false;
  Date startTime;
  Timer timeoutTimer;
  List<String> stdout;
  List<String> stderr;
  List<Function> handlers;

  RunningProcess(this.testCase);

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
    timeoutTimer = new Timer(timeoutHandler, 1000 * testCase.timeout, false);
  }

  void timeoutHandler(Timer unusedTimer) {
    timedOut = true;
    process.kill();
  }
}


class DartcBatchRunnerProcess {
  String _executable;

  Process _process;
  StringInputStream _stdoutStream;
  StringInputStream _stderrStream;

  TestCase _currentTest;
  StringBuffer _testStdout;
  StringBuffer _testStderr;
  Date _startTime;
  Timer _timer;

  DartcBatchRunnerProcess(String this._executable) {
    _startProcess();
  }

  bool get active() => _currentTest != null;

  void startTest(TestCase testCase) {
    _currentTest = testCase;
    if (testCase.executablePath != _executable) {
      // Restart this runner with the right executable for this test.
      _executable = testCase.executablePath;
      _process.exitHandler = (exitCode) {
        _process.close();
        _startProcess();
        doStartTest(testCase);
      };
      _process.kill();
    } else {
      doStartTest(testCase);
    }
  }

  void terminate() {
    _process.exitHandler = (exitCode) {
      _process.close();
    };
    _process.kill();
  }

  void doStartTest(TestCase testCase) {
    _startTime = new Date.now();
    _testStdout = new List<String>();
    _testStderr = new List<String>();
    _stdoutStream.dataHandler = _readOutput(_stdoutStream, _testStdout);
    _stderrStream.dataHandler = _readOutput(_stderrStream, _testStderr);
    _timer = new Timer(_timeoutHandler(testCase),
                       testCase.timeout * 1000,
                       false);
    _process.stdin.write(_createArgumentsLine(testCase.arguments).charCodes());
  }

  String _createArgumentsLine(List<String> arguments) {
    var buffer = new StringBuffer();
    for (var i = 0; i < arguments.length; i++) {
      buffer.add("${arguments[i]} ");
    }
    buffer.add("\n");
    return buffer.toString();
  }

  int _reportResult(String output) {
    var test = _currentTest;
    _currentTest = null;

    // output = '>>> TEST {PASS, FAIL, OK, CRASH, FAIL, TIMEOUT}'
    var outcome = output.split(" ")[2];
    var exitCode = 0;
    if (outcome == "CRASH") exitCode = -10;
    if (outcome == "FAIL" || outcome == "TIMEOUT") exitCode = 1;
    new TestOutput(test, exitCode, outcome == "TIMEOUT", _testStdout,
                   _testStderr, new Date.now().difference(_startTime));
    test.completed();
  }

  void _readOutput(StringInputStream stream, List<String> buffer) {
    return () {
      var status;
      var line = stream.readLine();
      // Drain the input stream to get the error output.
      while (line != null) {
        if (line.startsWith('>>> TEST')) {
          status = line;
        } else if (line.startsWith('>>> BATCH START')) {
          // ignore
        } else if (line.startsWith('>>> ')) {
          throw new Exception('Unexpected command from dartc batch runner.');
        } else {
          buffer.add(line);
        }
        line = stream.readLine();
      }
      if (status != null) {
        _timer.cancel();
        // For crashing processes, let the exit handler deal with it.
        if (!status.contains("CRASH")) {
          _reportResult(status);
        }
      }
    };
  }

  void _exitHandler(exitCode) {
    if (_timer != null) _timer.cancel();
    _process.close();
    _startProcess();
    _reportResult(">>> TEST CRASH");
  }

  void _timeoutHandler(TestCase test) {
    return (ignore) {
      _process.exitHandler = (exitCode) {
        _process.close();
        _startProcess();
        _reportResult(">>> TEST TIMEOUT");
      };
      _process.kill();
    };
  }

  void _startProcess() {
    _process = new Process(_executable, ['-batch']);
    _stdoutStream = new StringInputStream(_process.stdout);
    _stderrStream = new StringInputStream(_process.stderr);
    _testStdout = new List<String>();
    _testStderr = new List<String>();
    _stdoutStream.dataHandler = _readOutput(_stdoutStream, _testStdout);
    _stderrStream.dataHandler = _readOutput(_stderrStream, _testStderr);
    _process.exitHandler = _exitHandler;
    _process.start();
  }
}


class ProcessQueue {
  int _numProcesses = 0;
  int _activeTestListers = 0;
  int _maxProcesses;
  Function _enqueueMoreWork;
  Queue<TestCase> _tests;
  ProgressIndicator _progress;
  // For dartc batch processing we keep a list of batch processes.
  List<DartcBatchRunnerProcess> _batchProcesses;

  ProcessQueue(int this._maxProcesses,
               String progress,
               Date start_time,
               Function this._enqueueMoreWork)
      : _tests = new Queue<TestCase>(),
        _progress = new ProgressIndicator.fromName(progress, start_time),
        _batchProcesses = new List<DartcBatchRunnerProcess>() {
    _maxProcesses = _maxProcesses;
    if (!_enqueueMoreWork(this)) _progress.allDone();
  }

  void addTestSuite(TestSuite testSuite) {
    _activeTestListers++;
    testSuite.forEachTest(_runTest, _testListerDone);
  }

  void _testListerDone() {
    _activeTestListers--;
    _checkDone();
  }

  void _checkDone() {
    // When there are no more active test listers ask for more work
    // from process queue users.
    if (_activeTestListers == 0 && !_enqueueMoreWork(this)) {
      _progress.allTestsKnown();
      if (_tests.isEmpty() && _numProcesses == 0) {
        _terminateDartcBatchRunners();
        _progress.allDone();
      }
    }
  }

  void _runTest(TestCase test) {
    _progress.testAdded();
    _tests.add(test);
    _tryRunTest();
  }

  void _terminateDartcBatchRunners() {
    _batchProcesses.forEach((runner) => runner.terminate());
  }

  void _ensureDartcBatchRunnersStarted(String executable) {
    if (_batchProcesses.length == 0) {
      for (int i = 0; i < _maxProcesses; i++) {
        _batchProcesses.add(new DartcBatchRunnerProcess(executable));
      }
    }
  }

  DartcBatchRunnerProcess _getDartcBatchRunnerProcess() {
    for (int i = 0; i < _batchProcesses.length; i++) {
      var runner = _batchProcesses[i];
      if (!runner.active) return runner;
    }
    throw new Exception('Unable to find inactive batch runner.');
  }

  void _tryRunTest() {
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
      if (test.executablePath.contains('compiler')) {
        _ensureDartcBatchRunnersStarted(test.executablePath);
        _getDartcBatchRunnerProcess().startTest(test);
      } else {
        new RunningProcess(test).start();
      }
      _numProcesses++;
    }
  }
}
