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
#import("dart:builtin");
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

  String toString() => commandLine;
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
  List<Command> commands;

  Map configuration;
  String displayName;
  TestOutput output;
  bool isNegative;
  Set<String> expectedOutcomes;
  Function completedHandler;
  TestInformation info;

  TestCase(this.displayName,
           this.commands,
           this.configuration,
           this.completedHandler,
           this.expectedOutcomes,
           [this.isNegative = false,
            this.info = null]) {
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
      var prefix = specialCommandSplit[0].trim();
      var suffix = specialCommandSplit[1].trim();
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
        newArguments.addAll(c.arguments);
        var suffixSplit = suffix.split(' ');
        suffixSplit.forEach((e) {
          if (!e.isEmpty()) newArguments.add(e);
        });
        final newCommand = new Command(newExecutablePath, newArguments);
        newCommands.add(newCommand);
        // If there are extra spaces inside the prefix or suffix, this fails.
        Expect.stringEquals('$prefix ${c.commandLine} $suffix'.trim(),
            newCommand.commandLine);
      }
      commands = newCommands;
    }
  }

  int get timeout() => configuration['timeout'];

  String get configurationString() {
    final compiler = configuration['compiler'];
    final runtime = configuration['runtime'];
    final mode = configuration['mode'];
    final arch = configuration['arch'];
    return "$compiler-$runtime ${mode}_$arch";
  }

  List<String> get batchRunnerArguments() => ['-batch'];
  List<String> get batchTestArguments() => commands.last().arguments;

  void completed() { completedHandler(this); }

  bool get usesWebDriver() => (const ['chrome', 'dartium', 'ff', 'safari',
                                      'ie', 'opera'])
      .indexOf(configuration['runtime']) >= 0;
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
interface TestOutput default TestOutputImpl {
  TestOutput.fromCase(TestCase testCase, int exitCode, bool timedOut,
    List<String> stdout, List<String> stderr, Duration time);

  String get result();

  bool get unexpectedOutput();

  bool get hasCrashed();

  bool get hasTimedOut();

  bool get didFail();

  bool requestRetry;

  Duration get time();

  int get exitCode();

  List<String> get stdout();

  List<String> get stderr();

  List<String> get diagnostics();
}

class TestOutputImpl implements TestOutput {
  TestCase testCase;
  int exitCode;
  bool timedOut;
  bool failed = false;
  List<String> stdout;
  List<String> stderr;
  Duration time;
  List<String> diagnostics;

  /**
   * A flag to indicate we have already printed a warning about ignoring the VM
   * crash, to limit the amount of output produced per test.
   */
  bool alreadyPrintedWarning = false;

  /**
   * Set to true if we encounter a condition in the output that indicates we
   * need to rerun this test.
   */
  bool requestRetry = false;

  // Don't call  this constructor, call TestOutput.fromCase() to
  // get anew TestOutput instance.
  TestOutputImpl(TestCase this.testCase,
                 int this.exitCode,
                 bool this.timedOut,
                 List<String> this.stdout,
                 List<String> this.stderr,
                 Duration this.time) {
    testCase.output = this;
    diagnostics = [];
  }

  factory TestOutputImpl.fromCase (TestCase testCase, int exitCode, bool timedOut,
                                   List<String> stdout, List<String> stderr, Duration time) {
    if (testCase is BrowserTestCase) {
      return new BrowserTestOutputImpl(testCase, exitCode, timedOut,
        stdout, stderr, time);
    } else if (testCase.configuration['compiler'] == 'dartc') {
      return new AnalysisTestOutputImpl(testCase, exitCode, timedOut,
        stdout, stderr, time);
    }
    return new TestOutputImpl(testCase, exitCode, timedOut,
      stdout, stderr, time);
  }

  String get result() =>
      hasCrashed ? CRASH : (hasTimedOut ? TIMEOUT : (hasFailed ? FAIL : PASS));

  bool get unexpectedOutput() => !testCase.expectedOutcomes.contains(result);

  bool get hasCrashed() {
    if (Platform.operatingSystem() == 'windows') {
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
    return (exitCode != 0 && !hasCrashed);
  }

  // Reverse result of a negative test.
  bool get hasFailed() => testCase.isNegative ? !didFail : didFail;

}

class BrowserTestOutputImpl extends TestOutputImpl {
  BrowserTestOutputImpl(testCase, exitCode, timedOut, stdout, stderr, time) :
    super(testCase, exitCode, timedOut, stdout, stderr, time);

  bool get didFail() {
    // Browser case:
    // If the browser test failed, it may have been because DumpRenderTree
    // and the virtual framebuffer X server didn't hook up, or DRT crashed with
    // a core dump. Sometimes DRT crashes after it has set the stdout to PASS,
    // so we have to do this check first.
    for (String line in super.stderr) {
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
    // 'Content-Type: text/plain' followed by 'PASS'.
    bool has_content_type = false;
    for (String line in super.stdout) {
      switch (line) {
        case 'Content-Type: text/plain':
          has_content_type = true;
          break;

        case 'PASS':
          if (has_content_type) {
            return (exitCode != 0 && !hasCrashed);
          }
      }
    }
    return true;
  }
}

// The static analyzer does not actually execute code, so
// the criteria for success now depend on the text sent
// to stderr.
class AnalysisTestOutputImpl extends TestOutputImpl {
  // An error line has 8 fields that look like:
  // ERROR|COMPILER|MISSING_SOURCE|file:/tmp/t.dart|15|1|24|Missing source.
  final int ERROR_LEVEL = 0;
  final int ERROR_TYPE = 1;
  final int FORMATTED_ERROR = 7;

  bool alreadyComputed = false;
  bool failResult;
  AnalysisTestOutputImpl(testCase, exitCode, timedOut, stdout, stderr, time) :
    super(testCase, exitCode, timedOut, stdout, stderr, time) {
  }

  bool get didFail() {
    if (!alreadyComputed) {
      failResult = _didFail();
      alreadyComputed = true;
    }
    return failResult;
  }

  bool _didFail() {
    if (hasCrashed) return false;

    List<String> errors = [];
    List<String> staticWarnings = [];

    // Read the returned list of errors and stuff them away.
    for (String line in super.stderr) {
      if (line.length == 0) continue;
      List<String> fields = splitMachineError(line);
      if (fields[ERROR_LEVEL] == 'ERROR') {
        errors.add(fields[FORMATTED_ERROR]);
      } else if (fields[ERROR_LEVEL] == 'WARNING') {
        // We only care about testing Static type warnings
        // ignore all others
        if (fields[ERROR_TYPE] == 'STATIC_TYPE') {
          staticWarnings.add(fields[FORMATTED_ERROR]);
        }
      }
      // OK to Skip error output that doesn't match the machine format
    }
    if (testCase.info != null
        && testCase.info.optionsFromFile['isMultitest']) {
      return _didMultitestFail(errors, staticWarnings);
    }
    return _didStandardTestFail(errors, staticWarnings);
  }

  bool _didMultitestFail(List errors, List staticWarnings) {
    Set<String> outcome = testCase.info.multitestOutcome;
    Expect.isNotNull(outcome);
    if (outcome.contains('compile-time error') && errors.length > 0) {
      return true;
    } else if (outcome.contains('static type warning')
        && staticWarnings.length > 0) {
      return true;
    } else if (outcome.isEmpty()
        && (errors.length > 0 || staticWarnings.length > 0)) {
      return true;
    }
    return false;
  }

  bool _didStandardTestFail(List errors, List staticWarnings) {
    bool hasFatalTypeErrors = false;
    int numStaticTypeAnnotations = 0;
    int numCompileTimeAnnotations = 0;
    var isStaticClean = false;
    if (testCase.info != null) {
      var optionsFromFile = testCase.info.optionsFromFile;
      hasFatalTypeErrors = optionsFromFile['hasFatalTypeErrors'];
      for (Command c in testCase.commands) {
        for (String arg in c.arguments) {
          if (arg == '--fatal-type-errors') {
            hasFatalTypeErrors = true;
            break;
          }
        }
      }
      numStaticTypeAnnotations = optionsFromFile['numStaticTypeAnnotations'];
      numCompileTimeAnnotations = optionsFromFile['numCompileTimeAnnotations'];
      isStaticClean = optionsFromFile['isStaticClean'];
    }

    if (errors.length == 0) {
      if (!hasFatalTypeErrors && exitCode != 0) {
        diagnostics.add("EXIT CODE MISMATCH: Expected error message:");
        diagnostics.add("  command[0]:${testCase.commands[0]}");
        diagnostics.add("  exitCode:${exitCode}");
        return true;
      }
    } else if (exitCode == 0) {
      diagnostics.add("EXIT CODE MISMATCH: Unexpected error message:");
      diagnostics.add("  errors[0]:${errors[0]}");
      diagnostics.add("  command[0]:${testCase.commands[0]}");
      diagnostics.add("  exitCode:${exitCode}");
      return true;
    }
    if (numStaticTypeAnnotations > 0 && isStaticClean) {
      diagnostics.add("Cannot have both @static-clean and /// static type warning annotations.");
      return true;
    }

    if (isStaticClean && staticWarnings.length > 0) {
      diagnostics.add("@static-clean annotation found but analyzer returned warnings.");
      return true;
    }

    if (numCompileTimeAnnotations > 0
        && numCompileTimeAnnotations < errors.length) {

      // Expected compile-time errors were not returned.  The test did not 'fail' in the way
      // intended so don't return failed.
      diagnostics.add("Fewer compile time errors than annotated: ${numCompileTimeAnnotations}");
      return false;
    }

    if (numStaticTypeAnnotations > 0 || hasFatalTypeErrors) {
      // TODO(zundel): match up the annotation line numbers
      // with the reported error line numbers
      if (staticWarnings.length < numStaticTypeAnnotations) {
        diagnostics.add("Fewer static type warnings than annotated: ${numStaticTypeAnnotations}");
        return true;
      }
      return false;
    } else if (errors.length != 0) {
      return true;
    }
    return false;
  }

  // Parse a line delimited by the | character using \ as an escape charager
  // like:  FOO|BAR|FOO\|BAR|FOO\\BAZ as 4 fields: FOO BAR FOO|BAR FOO\BAZ
  List<String> splitMachineError(String line) {
    StringBuffer field = new StringBuffer();
    List<String> result = [];
    bool escaped = false;
    for (var i = 0 ; i < line.length; i++) {
      var c = line[i];
      if (!escaped && c == '\\') {
        escaped = true;
        continue;
      }
      escaped = false;
      if (c == '|') {
        result.add(field.toString());
        field.clear();
        continue;
      }
      field.add(c);
    }
    result.add(field.toString());
    return result;
  }
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
  bool allowRetries;

  /** Which command of [testCase.commands] is currently being executed. */
  int currentStep;

  RunningProcess(TestCase this.testCase,
      [this.allowRetries = false, this.processQueue]);

  /**
   * Called when all commands are executed. [exitCode] is 0 if all command
   * succeded, otherwise it will have the exit code of the first failing
   * command.
   */
  void testComplete(int exitCode) {
    new TestOutput.fromCase(testCase, exitCode, timedOut, stdout,
                            stderr, new Date.now().difference(startTime));
    timeoutTimer.cancel();
    if (testCase.output.unexpectedOutput
        && testCase.configuration['verbose'] != null
        && testCase.configuration['verbose']) {
      print(testCase.displayName);
      for (var line in testCase.output.stderr) print(line);
      for (var line in testCase.output.stdout) print(line);
    }
    if (allowRetries && testCase.usesWebDriver
        && testCase.output.unexpectedOutput
        && testCase.dynamic.numRetries > 0) {
      // Selenium tests can be flaky. Try rerunning.
      testCase.output.requestRetry = true;
    }
    if (testCase.output.requestRetry) {
      testCase.output.requestRetry = false;
      this.timedOut = false;
      testCase.dynamic.numRetries--;
      print("Potential flake. Re-running ${testCase.displayName} " +
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
      stderr.add('test.dart: Compilation finished $suffix\n');
      stdout.add('test.dart: Compilation finished $suffix\n');
      if (currentStep == totalSteps - 1 && testCase.usesWebDriver &&
          !testCase.configuration['noBatch']) {
        // Note: processQueue will always be non-null for runtime == ie, ff,
        // safari, chrome, opera. (It is only null for runtime == vm)
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
    if (Platform.operatingSystem() == 'windows') {
      // Windows can't handle the first command if it is a .bat file or the like
      // with the slashes going the other direction.
      // TODO(efortuna): Remove this when fixed (Issue 1306).
      command.executable = command.executable.replaceAll('/', '\\');
    }
    process = new Process.start(command.executable, command.arguments);
    process.onExit = exitHandler;
    process.onError = (e) {
      print("Error starting process:");
      print("  Command: $command");
      print("  Error: $e");
    };
    startTime = new Date.now();
    InputStream stdoutStream = process.stdout;
    InputStream stderrStream = process.stderr;
    StringInputStream stdoutStringStream = new StringInputStream(stdoutStream);
    StringInputStream stderrStringStream = new StringInputStream(stderrStream);
    stdoutStringStream.onLine =
        makeReadHandler(stdoutStringStream, stdout);
    stderrStringStream.onLine =
        makeReadHandler(stderrStringStream, stderr);
    if (timeoutTimer == null) {
      // Create one timeout timer when starting test case, remove it at end.
      timeoutTimer = new Timer(1000 * testCase.timeout, timeoutHandler);
    }
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
  bool _stdoutDrained = false;
  bool _stderrDrained = false;
  Date _startTime;
  Timer _timer;

  bool _isWebDriver;

  BatchRunnerProcess(TestCase testCase) {
    _executable = testCase.commands.last().executable;
    _batchArguments = testCase.batchRunnerArguments;
    _isWebDriver = testCase.usesWebDriver;
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
        int shutdownMillisecs = 30000;
        new Timer(shutdownMillisecs, (e) { if (!closed) _process.kill(); });
      } else {
        _process.kill();
      }
    }
  }

  void doStartTest(TestCase testCase) {
    _startTime = new Date.now();
    _testStdout = [];
    _testStderr = [];
    _stdoutDrained = false;
    _stderrDrained = false;
    _stdoutStream.onLine = _readStdout(_stdoutStream, _testStdout);
    _stderrStream.onLine = _readStderr(_stderrStream, _testStderr);
    _timer = new Timer(testCase.timeout * 1000, _timeoutHandler);
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
    _stdoutDrained = true;
    // output = '>>> TEST {PASS, FAIL, OK, CRASH, FAIL, TIMEOUT}'
    var outcome = output.split(" ")[2];
    var exitCode = 0;
    if (outcome == "CRASH") exitCode = -10;
    if (outcome == "FAIL" || outcome == "TIMEOUT") exitCode = 1;
    new TestOutput.fromCase(_currentTest, exitCode, outcome == "TIMEOUT",
                   _testStdout, _testStderr, new Date.now().difference(_startTime));
    // Move on when both stdout and stderr has been drained. If the test
    // crashed, we restarted the process and therefore do not attempt to
    // drain stderr.
    if (_stderrDrained || (_currentTest.output.hasCrashed)) _testCompleted();
  }

  void _stderrDone() {
    _stderrDrained = true;
    // Move on when both stdout and stderr has been drained.
    if (_stdoutDrained) _testCompleted();
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
    _stdoutDrained = false;
    _stderrDrained = false;
    _stdoutStream.onLine = _readStdout(_stdoutStream, _testStdout);
    _stderrStream.onLine = _readStderr(_stderrStream, _testStderr);
    _process.onExit = _exitHandler;
    _process.onError = (e) {
      print("Error starting process:");
      print("  Command: $_executable ${Strings.join(_batchArguments, ' ')}");
      print("  Error: $e");
    };
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
  String browserUsed = '';

  /**
   * Process running the selenium server .jar (only used for Safari and Opera
   * tests.)
   */
  Process _seleniumServer = null;

  /** True if we are in the process of starting the server. */
  bool _startingServer = false;

  /** True if we find that there is already a selenium jar running. */
  bool _seleniumAlreadyRunning = false;

  ProcessQueue(int this._maxProcesses,
               String progress,
               Date startTime,
               bool printTiming,
               Function this._enqueueMoreWork,
               [bool verbose = false,
                bool listTests = false,
                bool keepGeneratedTests = false])
      : _verbose = verbose,
        _listTests = listTests,
        _keepGeneratedTests = keepGeneratedTests,
        _tests = new Queue<TestCase>(),
        _progress = new ProgressIndicator.fromName(progress,
                                                   startTime,
                                                   printTiming),
        _batchProcesses = new Map<String, List<BatchRunnerProcess>>(),
        _testCache = new Map<String, List<TestInformation>>() {
    if (!_enqueueMoreWork(this)) _progress.allDone();
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

    if (Platform.operatingSystem() == 'windows') {
      throw new Exception(
          'Test suite requires temporary directory. Not supported on Windows.');
    }
    var tempDir = new Directory('');
    tempDir.createTempSync();
    _temporaryDirectory = tempDir.path;
    return _temporaryDirectory;
  }

  /**
   * Perform any cleanup needed once all tests in a TestSuite have completed
   * and notify our progress indicator that we are done.
   */
  void _cleanupAndMarkDone() {
    if (browserUsed != '' && _seleniumServer != null) {
        _seleniumServer.kill();
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
          Directory dir = new Directory(_temporaryDirectory);
          dir.deleteRecursively(() {
            _cleanupAndMarkDone();
          });
          dir.onError = (err) {
            print('\nDeletion of temp dir $_temporaryDirectory failed: $err');
          };
        }
      }
    }
  }

  /**
   * True if we are using a browser + platform combination that needs the
   * Selenium server jar.
   */
  bool get _needsSelenium() => Platform.operatingSystem() == 'macos' &&
      browserUsed == 'safari';

  /** True if the Selenium Server is ready to be used. */
  bool get _isSeleniumAvailable() => _seleniumServer != null ||
      _seleniumAlreadyRunning;

  /**
   * Restart all the processes that have been waiting/stopped for the server to
   * start up. If we just call this once we end up with a single-"threaded" run.
   */
  void resumeTesting() {
    for (int i = 0; i < _maxProcesses; i++) _tryRunTest();
  }

  /** Start the Selenium Server jar, if appropriate for this platform. */
  void _ensureSeleniumServerRunning() {
    if (!_isSeleniumAvailable && !_startingServer) {
      _startingServer = true;

      // Check to see if the jar was already running before the program started.
      String cmd = 'ps';
      var arg = ['aux'];
      if (Platform.operatingSystem() == 'windows') {
        cmd = 'tasklist';
        arg.add('/v');
      }
      Process p = new Process.start(cmd, arg);
      final StringInputStream stdoutStringStream =
          new StringInputStream(p.stdout);
      p.onError = (e) {
        print("Error starting process:");
        print("  Command: $cmd ${Strings.join(arg, ' ')}");
        print("  Error: $e");
      };
      stdoutStringStream.onLine = () {
        var line = stdoutStringStream.readLine();
        while (null != line) {
          if (const RegExp(@".*selenium-server-standalone.*").hasMatch(line)) {
            _seleniumAlreadyRunning = true;
            resumeTesting();
          }
          line = stdoutStringStream.readLine();
        }
        if (!_isSeleniumAvailable) {
          _startSeleniumServer();
        }
      };
    }
  }

  void _runTest(TestCase test) {
    if (test.usesWebDriver) {
      browserUsed = test.configuration['browser'];
      if (_needsSelenium) _ensureSeleniumServerRunning();
    }
    _progress.testAdded();
    _tests.add(test);
    _tryRunTest();
  }

  /**
   * Monitor the output of the Selenium server, to know when we are ready to
   * begin running tests.
   * source: Output(Stream) from the Java server.
   */
  Function makeSeleniumServerHandler(StringInputStream source) {
    return () {
      if (source.closed) return;  // TODO(whesse): Remove when bug is fixed.
      var line = source.readLine();
      while (null != line) {
        if (const RegExp(@".*Started.*Server.*").hasMatch(line) ||
            const RegExp(@"Exception.*Selenium is already running.*").hasMatch(
            line)) {
          resumeTesting();
        }
        line = source.readLine();
      }
    };
  }

  /**
   * For browser tests using Safari or Opera, we need to use the Selenium 1.0
   * Java server.
   */
  void _startSeleniumServer() {
    // Get the absolute path to the Selenium jar.
    String filePath = new Options().script;
    String pathSep = Platform.pathSeparator();
    int index = filePath.lastIndexOf(pathSep);
    filePath = filePath.substring(0, index) + '${pathSep}testing${pathSep}';
    var dir = new Directory(filePath);
    dir.onFile = (String file) {
      if (const RegExp(@"selenium-server-standalone-.*\.jar").hasMatch(file)
          && _seleniumServer == null) {
        _seleniumServer = new Process.start('java', ['-jar', file]);
        _seleniumServer.onError = (e) {
          print("Error starting process:");
          print("  Command: java -jar $file");
          print("  Error: $e");
        };
        // Heads up: there seems to an obscure data race of some form in
        // the VM between launching the server process and launching the test
        // tasks that disappears when you read IO (which is convenient, since
        // that is our condition for knowing that the server is ready).
        StringInputStream stdoutStringStream =
            new StringInputStream(_seleniumServer.stdout);
        StringInputStream stderrStringStream =
            new StringInputStream(_seleniumServer.stderr);
        stdoutStringStream.onLine =
            makeSeleniumServerHandler(stdoutStringStream);
        stderrStringStream.onLine =
            makeSeleniumServerHandler(stderrStringStream);
      }
    };
    dir.list();
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
    var compiler = test.configuration['compiler'];
    var runners = _batchProcesses[compiler];
    if (runners == null) {
      runners = new List<BatchRunnerProcess>(_maxProcesses);
      for (int i = 0; i < _maxProcesses; i++) {
        runners[i] = new BatchRunnerProcess(test);
      }
      _batchProcesses[compiler] = runners;
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
      if (_listTests) {
        final String tab = '\t';
        String outcomes =
            Strings.join(new List.from(test.expectedOutcomes), ',');
        print(test.displayName + tab + outcomes + tab + test.isNegative +
              tab + Strings.join(test.commands.last().arguments, tab));
        return;
      }
      if (test.usesWebDriver && _needsSelenium && !_isSeleniumAvailable) {
        // The server is not ready to run Selenium tests. Put the test back in
        // the queue.  Avoid spin-polling by using a timeout.
        _tests.add(test);
        new Timer(1000, (timer) {_tryRunTest();});  // Don't lose a process.
        return;
      }
      if (_verbose) {
        int i = 1;
        for (Command command in test.commands) {
          print('$i. ${command.commandLine}');
          i++;
        }
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
      if (test.configuration['compiler'] == 'dartc' &&
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
