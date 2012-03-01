// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Classes and methods for executing tests.
 *
 * This module includes:
 * - Managing parallel execution of tests, including timeout checks.
 * - Evaluating the output of each test as pass/fail/crash/timeout.
 */
#library("test_runner");

#import("dart:io");
#import("status_file_parser.dart");
#import("test_progress.dart");
#import("test_suite.dart");

final int NO_TIMEOUT = 0;

/** A command executed as a step in a test case. */
class Command {
  /** Path to the executable of this command. */
  String executable;

  /** Command line arguments to the executable. */
  List<String> arguments;

  /** The actual command line that will be executed. */
  String commandLine;

  Command(this.executable, this.arguments) {
    commandLine = "$executable ${Strings.join(arguments, ' ')}";
  }
}

/**
 * TestCase contains all the information needed to run a test and evaluate
 * its output.  Running a test involves starting a separate process, with
 * the executable and arguments given by the TestCase, and recording its
 * stdout and stderr output streams, and its exit code.  TestCase only
 * contains static information about the test; actually running the test is
 * performed by [ProcessQueue] using a [RunningProcess] object.
 *
 * The output information is stored in a [TestOutput] instance contained
 * in the TestCase. The TestOutput instance is responsible for evaluating
 * if the test has passed, failed, crashed, or timed out, and the TestCase
 * has information about what the expected result of the test should be.
 *
 * The TestCase has a callback function, [completedHandler], that is run when
 * the test is completed.
 */
class TestCase {
  /**
   * A list of commands to execute. Most test cases have a single command. Frog
   * tests have two commands, one to compilate the source and another to execute
   * it. Some isolate tests might even have three, if they require compiling
   * multiple sources that are run in isolation.
   */
  final List<Command> commands;

  Map configuration;
  String displayName;
  TestOutput output;
  bool isNegative;
  Set<String> expectedOutcomes;
  Function completedHandler;

  TestCase(this.displayName,
           this.commands,
           this.configuration,
           this.completedHandler,
           this.expectedOutcomes,
           [this.isNegative = false]) {
    if (!isNegative) {
      this.isNegative = displayName.contains("NegativeTest");
    }

    // Special command handling. If a special command is specified
    // we have to completely rewrite the command that we are using.
    // We generate a new command-line that is the special command
    // where we replace '@' with the original command.
    var specialCommand = configuration['special-command'];
    if (!specialCommand.isEmpty()) {
      Expect.isTrue(specialCommand.contains('@'),
                    "special-command must contain a '@' char");
      var specialCommandSplit = specialCommand.split('@');
      var prefix = specialCommandSplit[0];
      var suffix = specialCommandSplit[1];
      List<Command> newCommands = [];
      for (Command c in commands) {
        var newExecutablePath;
        var newArguments = [];

        if (prefix.length > 0) {
          var prefixSplit = prefix.split(' ');
          newExecutablePath = prefixSplit[0];
          for (int i = 1; i < prefixSplit.length; i++) {
            var current = prefixSplit[i];
            if (!current.isEmpty()) newArguments.add(current);
          }
          newArguments.add(c.executable);
        }
        newArguments.addAll(arguments);
        var suffixSplit = suffix.split(' ');
        suffixSplit.forEach((e) {
          if (!e.isEmpty()) newArguments.add(e);
        });
        final newCommand = new Command(newExecutablePath, newArguments);
        newCommands.add(newCommand);
        Expect.stringEquals('$prefix ${c.commandLine} $suffix',
            newCommand.commandLine);
      }
      commands = newCommand;
    }
  }

  int get timeout() => configuration['timeout'];

  String get configurationString() {
    final component = configuration['component'];
    final mode = configuration['mode'];
    final arch = configuration['arch'];
    return "$component ${mode}_$arch";
  }

  List<String> get batchRunnerArguments() => ['-batch'];
  List<String> get batchTestArguments() => commands.last().arguments;

  void completed() { completedHandler(this); }
}


/**
 * BrowserTestCase has an extra compilation command that is run in a separate
 * process, before the regular test is run as in the base class [TestCase].
 * If the compilation command fails, then the rest of the test is not run.
 */
class BrowserTestCase extends TestCase {
  /**
   * Indicates the number of potential retries remaining, to compensate for
   * flaky browser tests.
   */
  int numRetries;

  BrowserTestCase(displayName, commands, configuration, completedHandler,
      expectedOutcomes, [isNegative = false])
    : super(displayName, commands, configuration, completedHandler,
        expectedOutcomes, isNegative) {
    numRetries = 2; // Allow two retries to compensate for flaky browser tests.
  }

  List<String> get _lastArguments() => commands.last().arguments;

  List<String> get batchRunnerArguments() => [_lastArguments[0], '--batch'];

  List<String> get batchTestArguments() =>
      _lastArguments.getRange(1, _lastArguments.length - 1);
}


/**
 * TestOutput records the output of a completed test: the process's exit code,
 * the standard output and standard error, whether the process timed out, and
 * the time the process took to run.  It also contains a pointer to the
 * [TestCase] this is the output of.
 */
class TestOutput {
  TestCase testCase;
  int exitCode;
  bool timedOut;
  bool failed = false;
  List<String> stdout;
  List<String> stderr;
  Duration time;
  /**
   * Set to true if we encounter a condition in the output that indicates we
   * need to rerun this test.
   */
  bool requestRetry;

  TestOutput(this.testCase, this.exitCode, this.timedOut, this.stdout,
             this.stderr, this.time) {
    testCase.output = this;
    requestRetry = false;
  }

  String get result() =>
      hasCrashed ? CRASH : (hasTimedOut ? TIMEOUT : (hasFailed ? FAIL : PASS));

  bool get unexpectedOutput() => !testCase.expectedOutcomes.contains(result);

  bool get hasCrashed() {
    if (new Platform().operatingSystem() == 'windows') {
      // The VM uses std::abort to terminate on asserts.
      // std::abort terminates with exit code 3 on Windows.
      if (exitCode == 3) {
        return !timedOut;
      }
      return (!timedOut && (exitCode < 0) && ((0x3FFFFF00 & exitCode) == 0));
    }
    // The Java dartc runner exits with code 253 in case of unhandled
    // exceptions.
    return (!timedOut && ((exitCode < 0) || (exitCode == 253)));
  }

  bool get hasTimedOut() => timedOut;

  bool get didFail() {
    if (testCase is !BrowserTestCase) return (exitCode != 0 && !hasCrashed);

    // Browser case:
    // If the browser test failed, it may have been because DumpRenderTree
    // and the virtual framebuffer X server didn't hook up, or DRT crashed with
    // a core dump. Sometimes DRT crashes after it has set the stdout to PASS,
    // so we have to do this check first.
    for (String line in stderr) {
      if (line.contains('Gtk-WARNING **: cannot open display: :99') ||
        line.contains('Failed to run command. return code=1')) {
        // If we get the X server error, or DRT crashes with a core dump, retry
        // the test.
        if (testCase.dynamic.numRetries > 0) {
          requestRetry = true;
        }
        return true;
      }
    }

    // Browser tests fail unless stdout contains
    // 'Content-Type: text/plain\nPASS'.
    String previous_line = '';
    for (String line in stdout) {
      if (line == 'PASS' && previous_line == 'Content-Type: text/plain') {
        return (exitCode != 0 && !hasCrashed);
      }
      previous_line = line;
    }

    return true;
  }

  // Reverse result of a negative test.
  bool get hasFailed() => (testCase.isNegative ? !didFail : didFail);
}

/**
 * A RunningProcess actually runs a test, getting the command lines from
 * its [TestCase], starting the test process (and first, a compilation
 * process if the TestCase is a [BrowserTestCase]), creating a timeout
 * timer, and recording the results in a new [TestOutput] object, which it
 * attaches to the TestCase.  The lifetime of the RunningProcess is limited
 * to the time it takes to start the process, run the process, and record
 * the result; there are no pointers to it, so it should be available to
 * be garbage collected as soon as it is done.
 */
class RunningProcess {
  ProcessQueue processQueue;
  Process process;
  TestCase testCase;
  bool timedOut = false;
  Date startTime;
  Timer timeoutTimer;
  List<String> stdout;
  List<String> stderr;
  List<Function> handlers;
  bool allowRetries = false;

  /** Which command of [testCase.commands] is currently being executed. */
  int currentStep;

  RunningProcess(TestCase this.testCase,
      [this.allowRetries, this.processQueue]);

  /**
   * Called when all commands are executed. [exitCode] is 0 if all command
   * succeded, otherwise it will have the exit code of the first failing
   * command.
   */
  void testComplete(int exitCode) {
    new TestOutput(testCase, exitCode, timedOut, stdout,
                   stderr, new Date.now().difference(startTime));
    timeoutTimer.cancel();
    if (testCase.output.unexpectedOutput && testCase.configuration['verbose']) {
      print(testCase.displayName);
      for (var line in testCase.output.stderr) print(line);
      for (var line in testCase.output.stdout) print(line);
    }
    if (allowRetries != null && allowRetries
        && testCase.configuration['component'] == 'webdriver' &&
        testCase.output.unexpectedOutput && testCase.numRetries > 0) {
      // Selenium tests can be flaky. Try rerunning.
      testCase.output.requestRetry = true;
    }
    if (testCase.output.requestRetry) {
      testCase.output.requestRetry = false;
      this.timedOut = false;
      testCase.dynamic.numRetries--;
      print("Potential flake. " +
          "Re-running ${testCase.displayName} " +
          "(${testCase.dynamic.numRetries} attempt(s) remains)");
      this.start();
    } else {
      testCase.completed();
    }
  }

  /**
   * Process exit handler called at the end of every command. It internally
   * treats all but the last command as compilation steps. The last command is
   * the actual test and its output is analyzed in [testComplete].
   */
  void stepExitHandler(int exitCode) {
    process.close();
    int totalSteps = testCase.commands.length;
    String suffix =' (step $currentStep of $totalSteps)';
    if (currentStep == totalSteps) { // done with test command
      testComplete(exitCode);
    } else if (exitCode != 0) {
      stderr.add('test.dart: Compilation failed$suffix, exit code $exitCode\n');
      testComplete(exitCode);
    } else {
      stderr.add('test.dart: Compilion finished $suffix\n');
      stdout.add('test.dart: Compilion finished $suffix\n');
      if (currentStep == totalSteps - 1
          && testCase.configuration['component'] == 'webdriver') {
        // Note: processQueue will always be non-null for component == webdriver
        // (It is only null for component == vm)
        processQueue._getBatchRunner(testCase).startTest(testCase);
      } else {
        runCommand(testCase.commands[currentStep++], stepExitHandler);
      }
    }
  }

  Function makeReadHandler(StringInputStream source, List<String> destination) {
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
    stdout = new List<String>();
    stderr = new List<String>();
    currentStep = 0;
    runCommand(testCase.commands[currentStep++], stepExitHandler);
  }

  void runCommand(Command command,
                  void exitHandler(int exitCode)) {
    if (new Platform().operatingSystem() == 'windows') {
      // Windows can't handle the first command if it is a .bat file or the like
      // with the slashes going the other direction.
      // TODO(efortuna): Remove this when fixed (Issue 1306).
      command.executable = command.executable.replaceAll('/', '\\');
    }
    process = new Process.start(command.executable, command.arguments);
    process.onExit = exitHandler;
    startTime = new Date.now();
    InputStream stdoutStream = process.stdout;
    InputStream stderrStream = process.stderr;
    StringInputStream stdoutStringStream = new StringInputStream(stdoutStream);
    StringInputStream stderrStringStream = new StringInputStream(stderrStream);
    stdoutStringStream.onLine =
        makeReadHandler(stdoutStringStream, stdout);
    stderrStringStream.onLine =
        makeReadHandler(stderrStringStream, stderr);
    timeoutTimer = new Timer(timeoutHandler, 1000 * testCase.timeout);
  }

  void timeoutHandler(Timer unusedTimer) {
    timedOut = true;
    process.kill();
  }
}

class BatchRunnerProcess {
  String _executable;
  List<String> _batchArguments;

  Process _process;
  StringInputStream _stdoutStream;
  StringInputStream _stderrStream;

  TestCase _currentTest;
  List<String> _testStdout;
  List<String> _testStderr;
  bool _stderrDrained = false;
  Date _startTime;
  Timer _timer;

  bool _isWebDriver;

  BatchRunnerProcess(TestCase testCase) {
    _executable = testCase.commands.last().executable;
    _batchArguments = testCase.batchRunnerArguments;
    _isWebDriver = testCase.configuration['component'] == 'webdriver';
  }

  bool get active() => _currentTest != null;

  void startTest(TestCase testCase) {
    _currentTest = testCase;
    if (_process === null) {
      // Start process if not yet started.
      _executable = testCase.commands.last().executable;
      _startProcess(() {
        doStartTest(testCase);
      });
    } else if (testCase.commands.last().executable != _executable) {
      // Restart this runner with the right executable for this test
      // if needed.
      _executable = testCase.commands.last().executable;
      _batchArguments = testCase.batchRunnerArguments;
      _process.onExit = (exitCode) {
        _process.close();
        _startProcess(() {
          doStartTest(testCase);
        });
      };
      _process.kill();
    } else {
      doStartTest(testCase);
    }
  }

  void terminate() {
    if (_process !== null) {
      bool closed = false;
      _process.onExit = (exitCode) {
        closed = true;
        _process.close();
      };
      if (_isWebDriver) {
        // Use a graceful shutdown so our Selenium script can close
        // the open browser processes. TODO(jmesserly): Send a signal once
        // that's supported, see dartbug.com/1756.
        _process.stdin.write('--terminate\n'.charCodes());

        // In case the run_selenium process didn't close, kill it after 30s
        bool shutdownMillisecs = 30000;
        new Timer((e) { if (!closed) _process.kill(); }, shutdownMillisecs);
      } else {
        _process.kill();
      }
    }
  }

  void doStartTest(TestCase testCase) {
    _startTime = new Date.now();
    _testStdout = new List<String>();
    _testStderr = new List<String>();
    _stderrDrained = false;
    _stdoutStream.onLine = _readStdout(_stdoutStream, _testStdout);
    _stderrStream.onLine = _readStderr(_stderrStream, _testStderr);
    _timer = new Timer(_timeoutHandler, testCase.timeout * 1000);
    var line = _createArgumentsLine(testCase.batchTestArguments);
    _process.stdin.write(line.charCodes());
  }

  String _createArgumentsLine(List<String> arguments) {
    return Strings.join(arguments, ' ') + '\n';
  }

  void _testCompleted() {
    var test = _currentTest;
    _currentTest = null;
    test.completed();
  }

  int _reportResult(String output) {
    // output = '>>> TEST {PASS, FAIL, OK, CRASH, FAIL, TIMEOUT}'
    var outcome = output.split(" ")[2];
    var exitCode = 0;
    if (outcome == "CRASH") exitCode = -10;
    if (outcome == "FAIL" || outcome == "TIMEOUT") exitCode = 1;
    new TestOutput(_currentTest, exitCode, outcome == "TIMEOUT", _testStdout,
                   _testStderr, new Date.now().difference(_startTime));
    // Move on when both stdout and stderr has been drained.
    if (_stderrDrained) _testCompleted();
  }

  void _stderrDone() {
    _stderrDrained = true;
    // Move on when both stdout and stderr has been drained.
    if (_currentTest.output != null) _testCompleted();
  }

  Function _readStdout(StringInputStream stream, List<String> buffer) {
    return () {
      var status;
      var line = stream.readLine();
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

  Function _readStderr(StringInputStream stream, List<String> buffer) {
    return () {
      var line = stream.readLine();
      while (line != null) {
        if (line.startsWith('>>> EOF STDERR')) {
          _stderrDone();
        } else {
          buffer.add(line);
        }
        line = stream.readLine();
      }
    };
  }

  void _exitHandler(exitCode) {
    if (_timer != null) _timer.cancel();
    _process.close();
    _startProcess(() {
      _reportResult(">>> TEST CRASH");
    });
  }

  void _timeoutHandler(ignore) {
    _process.onExit = (exitCode) {
      _process.close();
      _startProcess(() {
        _reportResult(">>> TEST TIMEOUT");
      });
    };
    _process.kill();
  }

  void _startProcess(then) {
    _process = new Process.start(_executable, _batchArguments);
    _stdoutStream = new StringInputStream(_process.stdout);
    _stderrStream = new StringInputStream(_process.stderr);
    _testStdout = new List<String>();
    _testStderr = new List<String>();
    _stderrDrained = false;
    _stdoutStream.onLine = _readStdout(_stdoutStream, _testStdout);
    _stderrStream.onLine = _readStderr(_stderrStream, _testStderr);
    _process.onExit = _exitHandler;
    _process.onStart = then;
  }
}

/**
 * ProcessQueue is the master control class, responsible for running all
 * the tests in all the TestSuites that have been registered.  It includes
 * a rate-limited queue to run a limited number of tests in parallel,
 * a ProgressIndicator which prints output when tests are started and
 * and completed, and a summary report when all tests are completed,
 * and counters to determine when all of the tests in all of the test suites
 * have completed.
 *
 * Because multiple configurations may be run on each test suite, the
 * ProcessQueue contains a cache in which a test suite may record information
 * about its list of tests, and may retrieve that information when it is called
 * upon to enqueue its tests again.
 */
class ProcessQueue {
  int _numProcesses = 0;
  int _activeTestListers = 0;
  int _maxProcesses;
  /** The number of tests we allow to actually fail before we stop retrying. */
  int _MAX_FAILED_NO_RETRY = 4;
  bool _verbose;
  bool _listTests;
  bool _keepGeneratedTests;
  Function _enqueueMoreWork;
  Queue<TestCase> _tests;
  ProgressIndicator _progress;
  String _temporaryDirectory;
  // For dartc/selenium batch processing we keep a list of batch processes.
  Map<String, List<BatchRunnerProcess>> _batchProcesses;

  // Cache information about test cases per test suite. For multiple
  // configurations there is no need to repeatedly search the file
  // system, generate tests, and search test files for options.
  Map<String, List<TestInformation>> _testCache;
  /**
   * String indicating the browser used to run the tests. Empty if no browser
   * used.
   */
  String browserUsed;

  ProcessQueue(int this._maxProcesses,
               String progress,
               Date startTime,
               bool printTiming,
               Function this._enqueueMoreWork,
               [bool this._verbose = false,
                bool this._listTests = false,
                bool this._keepGeneratedTests = false])
      : _tests = new Queue<TestCase>(),
        _progress = new ProgressIndicator.fromName(progress,
                                                   startTime,
                                                   printTiming),
        _batchProcesses = new Map<String, List<BatchRunnerProcess>>(),
        _testCache = new Map<String, List<TestInformation>>() {
    if (!_enqueueMoreWork(this)) _progress.allDone();
    browserUsed = '';
  }

  /**
   * Registers a TestSuite so that all of its tests will be run.
   */
  void addTestSuite(TestSuite testSuite) {
    _activeTestListers++;
    testSuite.forEachTest(_runTest, _testCache, globalTemporaryDirectory,
                          _testListerDone);
  }

  void _testListerDone() {
    _activeTestListers--;
    _checkDone();
  }

  String globalTemporaryDirectory() {
    if (_temporaryDirectory != null) return _temporaryDirectory;

    if (new Platform().operatingSystem() == 'windows') {
      throw new Exception(
          'Test suite requires temporary directory. Not supported on Windows.');
    }
    var tempDir = new Directory('');
    tempDir.createTempSync();
    _temporaryDirectory = tempDir.path;
    return _temporaryDirectory;
  }

  /**
   * Sometimes Webdriver doesn't close every browser window when it's done
   * with a test. At the end of all tests we clear out any neglected processes
   * that are still running.
   */
  void killZombieBrowsers() {
    String chromeName = 'chrome';
    if (new Platform().operatingSystem() == 'macos') {
      chromeName = 'Google\ Chrome';
    }
    Map<String, List<String>> processNames = {'ie': ['iexplore'],
        'safari': ['Safari'], 'ff': ['firefox', 'firefox-bin'],
        'chrome': ['chromedriver', chromeName]};
    for (String name in processNames[browserUsed]) {
      Process process = null;
      if (new Platform().operatingSystem() == 'windows') {
        process = new Process.start(
            'C:\\Windows\\System32\\taskkill.exe', ['/F', '/IM', name + '.exe',
            '/T']);
      } else {
        process = new Process.start('killall', ['-9', name]);
      }

      if (name == processNames[browserUsed].last()) {
        process.onExit = (exitCode) {
          process.close();
          _progress.allDone();
        };
        process.onError = (error) {
          _progress.allDone();
        };
      } else {
        process.onExit = (exitCode) {
          process.close();
        };
      }
    }
  }

  /**
   * Perform any cleanup needed once all tests in a TestSuite have completed
   * and notify our progress indicator that we are done.
   */
  void _cleanupAndMarkDone() {
    if (browserUsed != '') {
      killZombieBrowsers();
    } else {
      _progress.allDone();
    }
  }

  void _checkDone() {
    // When there are no more active test listers ask for more work
    // from process queue users.
    if (_activeTestListers == 0 && !_enqueueMoreWork(this)) {
      _progress.allTestsKnown();
      if (_tests.isEmpty() && _numProcesses == 0) {
        _terminateBatchRunners();
        if (_keepGeneratedTests || _temporaryDirectory == null) {
          _cleanupAndMarkDone();
        } else if (!_temporaryDirectory.startsWith('/tmp/') ||
                   _temporaryDirectory.contains('/../')) {
          // Let's be extra careful, since rm -rf is so dangerous.
          print('Temporary directory $_temporaryDirectory unsafe to delete!');
          _cleanupAndMarkDone();
        } else {
          // TODO(dart:1211): Use delete(recursive=true) in Dart when it is
          // implemented, and add Windows support.
          var deletion =
              new Process.start('/bin/rm', ['-rf', _temporaryDirectory]);
          deletion.onExit = (int exitCode) {
            if (exitCode == 0) {
              if (!_listTests) {  // Output of --list option is used by scripts.
                print('\nTemporary directory $_temporaryDirectory deleted.');
              }
            } else {
              print('\nDeletion of temp dir $_temporaryDirectory failed.');
            }
            _cleanupAndMarkDone();
          };
        }
      }
    }
  }

  void _runTest(TestCase test) {
    if (test.configuration['component'] == 'webdriver') {
      browserUsed = test.configuration['browser'];
    }
    _progress.testAdded();
    _tests.add(test);
    _tryRunTest();
  }

  void _terminateBatchRunners() {
    for (var runners in _batchProcesses.getValues()) {
      for (var runner in runners) {
        runner.terminate();
      }
    }
  }

  BatchRunnerProcess _getBatchRunner(TestCase test) {
    // Start batch processes if needed
    var component = test.configuration['component'];
    var runners = _batchProcesses[component];
    if (runners == null) {
      runners = new List<BatchRunnerProcess>(_maxProcesses);
      for (int i = 0; i < _maxProcesses; i++) {
        runners[i] = new BatchRunnerProcess(test);
      }
      _batchProcesses[component] = runners;
    }

    for (var runner in runners) {
      if (!runner.active) return runner;
    }
    throw new Exception('Unable to find inactive batch runner.');
  }

  void _tryRunTest() {
    _checkDone();
    if (_numProcesses < _maxProcesses && !_tests.isEmpty()) {
      TestCase test = _tests.removeFirst();
      if (_verbose) print(test.commands.last().commandLine);
      if (_listTests) {
        final String tab = '\t';
        String outcomes =
            Strings.join(new List.from(test.expectedOutcomes), ',');
        print(test.displayName + tab + outcomes + tab + test.isNegative +
              tab + Strings.join(test.commands.last().arguments, tab));
        return;
      }
      _progress.start(test);
      Function oldCallback = test.completedHandler;
      Function wrapper = (TestCase test_arg) {
        _numProcesses--;
        _progress.done(test_arg);
        _tryRunTest();
        oldCallback(test_arg);
      };
      test.completedHandler = wrapper;
      if (test.configuration['component'] == 'dartc' &&
          test.displayName != 'dartc/junit_tests') {
        _getBatchRunner(test).startTest(test);
      } else {
        // Once we've actually failed a test, technically, we wouldn't need to
        // bother retrying any subsequent tests since the bot is already red.
        // However, we continue to retry tests until we have actually failed
        // four tests (arbitrarily chosen) for more debugable output, so that
        // the developer doesn't waste his or her time trying to fix a bunch of
        // tests that appear to be broken but were actually just flakes that
        // didn't get retried because there had already been one failure.
        bool allowRetry = _MAX_FAILED_NO_RETRY > _progress.numFailedTests;
        new RunningProcess(test, allowRetry, this).start();
      }
      _numProcesses++;
    }
  }
}
