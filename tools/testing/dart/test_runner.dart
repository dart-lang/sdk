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
library test_runner;

import "dart:async";
import "dart:collection" show Queue;
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import "dart:io" as io;
import "dart:isolate";
import "dart:uri";
import "http_server.dart" as http_server;
import "status_file_parser.dart";
import "test_progress.dart";
import "test_suite.dart";
import "utils.dart";

const int NO_TIMEOUT = 0;
const int SLOW_TIMEOUT_MULTIPLIER = 4;

const int CRASHING_BROWSER_EXITCODE = -10;

typedef void TestCaseEvent(TestCase testCase);
typedef void ExitCodeEvent(int exitCode);
typedef void EnqueueMoreWork(ProcessQueue queue);

// Some IO tests use these variables and get confused if the host environment
// variables are inherited so they are excluded.
const List<String> EXCLUDED_ENVIRONMENT_VARIABLES =
    const ['http_proxy', 'https_proxy', 'no_proxy',
           'HTTP_PROXY', 'HTTPS_PROXY', 'NO_PROXY'];


/**
 * [areByteArraysEqual] compares a range of bytes from [buffer1] with a
 * range of bytes from [buffer2].
 *
 * Returns [true] if the [count] bytes in [buffer1] (starting at
 * [offset1]) match the [count] bytes in [buffer2] (starting at
 * [offset2]).
 * Otherwise [false] is returned.
 */
bool areByteArraysEqual(List<int> buffer1, int offset1,
                        List<int> buffer2, int offset2,
                        int count) {
  if ((offset1 + count) > buffer1.length ||
      (offset2 + count) > buffer2.length) {
    return false;
  }

  for (var i = 0; i < count; i++) {
    if (buffer1[offset1 + i] != buffer2[offset2 + i]) {
      return false;
    }
  }
  return true;
}

/**
 * [findBytes] searches for [pattern] in [data] beginning at [startPos].
 *
 * Returns [true] if [pattern] was found in [data].
 * Otherwise [false] is returned.
 */
int findBytes(List<int> data, List<int> pattern, [int startPos=0]) {
  // TODO(kustermann): Use one of the fast string-matching algorithms!
  for (int i=startPos; i < (data.length-pattern.length); i++) {
    bool found = true;
    for (int j=0; j<pattern.length; j++) {
      if (data[i+j] != pattern[j]) {
        found = false;
      }
    }
    if (found) {
      return i;
    }
  }
  return -1;
}


/** A command executed as a step in a test case. */
class Command {
  static int nextHashCode = 0;
  final int hashCode = nextHashCode++;
  operator ==(other) => super == (other);

  /** Path to the executable of this command. */
  String executable;

  /** Command line arguments to the executable. */
  List<String> arguments;

  /** Environment for the command */
  Map<String,String> environment;

  /** The actual command line that will be executed. */
  String commandLine;

  Command(this.executable, this.arguments, [this.environment = null]) {
    if (io.Platform.operatingSystem == 'windows') {
      // Windows can't handle the first command if it is a .bat file or the like
      // with the slashes going the other direction.
      // TODO(efortuna): Remove this when fixed (Issue 1306).
      executable = executable.replaceAll('/', '\\');
    }
    var quotedArguments = [];
    arguments.forEach((argument) => quotedArguments.add('"$argument"'));
    commandLine = "$executable ${quotedArguments.join(' ')}";
  }

  String toString() => commandLine;

  Future<bool> get outputIsUpToDate => new Future.immediate(false);
  io.Path get expectedOutputFile => null;
  bool get isPixelTest => false;
}

class CompilationCommand extends Command {
  String _outputFile;
  bool _neverSkipCompilation;
  List<Uri> _bootstrapDependencies;

  CompilationCommand(this._outputFile,
                     this._neverSkipCompilation,
                     this._bootstrapDependencies,
                     String executable,
                     List<String> arguments)
      : super(executable, arguments);

  Future<bool> get outputIsUpToDate {
    if (_neverSkipCompilation) return new Future.immediate(false);

    Future<List<Uri>> readDepsFile(String path) {
      var file = new io.File(new io.Path(path).toNativePath());
      if (!file.existsSync()) {
        return new Future.immediate(null);
      }
      return file.readAsLines().then((List<String> lines) {
        var dependencies = new List<Uri>();
        for (var line in lines) {
          line = line.trim();
          if (line.length > 0) {
            dependencies.add(new Uri(line));
          }
        }
        return dependencies;
      });
    }

    return readDepsFile("$_outputFile.deps").then((dependencies) {
      if (dependencies != null) {
        dependencies.addAll(_bootstrapDependencies);
        var jsOutputLastModified = TestUtils.lastModifiedCache.getLastModified(
            new Uri.fromComponents(scheme: 'file', path: _outputFile));
        if (jsOutputLastModified != null) {
          for (var dependency in dependencies) {
            var dependencyLastModified =
                TestUtils.lastModifiedCache.getLastModified(dependency);
            if (dependencyLastModified == null ||
                dependencyLastModified.isAfter(jsOutputLastModified)) {
              return false;
            }
          }
          return true;
        }
      }
      return false;
    });
  }
}

class DumpRenderTreeCommand extends Command {
  /**
   * If [expectedOutputPath] is set, the output of DumpRenderTree is compared
   * with the content of [expectedOutputPath].
   * This is used for example for pixel tests, where [expectedOutputPath] points
   * to a *png file.
   */
  io.Path expectedOutputPath;

  DumpRenderTreeCommand(String executable,
                        String htmlFile,
                        List<String> options,
                        List<String> dartFlags,
                        io.Path this.expectedOutputPath)
      : super(executable,
              _getArguments(options, htmlFile),
              _getEnvironment(dartFlags));

  static Map _getEnvironment(List<String> dartFlags) {
    var needDartFlags = dartFlags != null && dartFlags.length > 0;

    var env = null;
    if (needDartFlags) {
      env = new Map.from(io.Platform.environment);
      if (needDartFlags) {
        env['DART_FLAGS'] = dartFlags.join(" ");
      }
    }

    return env;
  }

  static List<String> _getArguments(List<String> options, String htmlFile) {
    var arguments = new List.from(options);
    arguments.add(htmlFile);
    return arguments;
  }

  io.Path get expectedOutputFile => expectedOutputPath;
  bool get isPixelTest => (expectedOutputFile != null &&
                           expectedOutputFile.filename.endsWith(".png"));
}


/**
 * TestCase contains all the information needed to run a test and evaluate
 * its output.  Running a test involves starting a separate process, with
 * the executable and arguments given by the TestCase, and recording its
 * stdout and stderr output streams, and its exit code.  TestCase only
 * contains static information about the test; actually running the test is
 * performed by [ProcessQueue] using a [RunningProcess] object.
 *
 * The output information is stored in a [CommandOutput] instance contained
 * in TestCase.commandOutputs. The last CommandOutput instance is responsible
 * for evaluating if the test has passed, failed, crashed, or timed out, and the
 * TestCase has information about what the expected result of the test should
 * be.
 *
 * The TestCase has a callback function, [completedHandler], that is run when
 * the test is completed.
 */
class TestCase {
  /**
   * A list of commands to execute. Most test cases have a single command.
   * Dart2js tests have two commands, one to compile the source and another
   * to execute it. Some isolate tests might even have three, if they require
   * compiling multiple sources that are run in isolation.
   */
  List<Command> commands;
  Map<Command, CommandOutput> commandOutputs = new Map<Command,CommandOutput>();

  Map configuration;
  String displayName;
  bool isNegative;
  Set<String> expectedOutcomes;
  TestCaseEvent completedHandler;
  TestInformation info;

  TestCase(this.displayName,
           this.commands,
           this.configuration,
           this.completedHandler,
           this.expectedOutcomes,
           {this.isNegative: false,
            this.info: null}) {
    if (!isNegative) {
      this.isNegative = displayName.contains("negative_test");
    }

    // Special command handling. If a special command is specified
    // we have to completely rewrite the command that we are using.
    // We generate a new command-line that is the special command where we
    // replace '@' with the original command executable, and generate
    // a command formed like the following
    // Let PREFIX be what is before the @.
    // Let SUFFIX be what is after the @.
    // Let EXECUTABLE be the existing executable of the command.
    // Let ARGUMENTS be the existing arguments to the existing executable.
    // The new command will be:
    // PREFIX EXECUTABLE SUFFIX ARGUMENTS
    var specialCommand = configuration['special-command'];
    if (!specialCommand.isEmpty) {
      if (!specialCommand.contains('@')) {
        throw new FormatException("special-command must contain a '@' char");
      }
      var specialCommandSplit = specialCommand.split('@');
      var prefix = specialCommandSplit[0].trim();
      var suffix = specialCommandSplit[1].trim();
      List<Command> newCommands = [];
      for (Command c in commands) {
        // If we don't have a new prefix we will use the existing executable.
        var newExecutablePath = c.executable;;
        var newArguments = [];

        if (prefix.length > 0) {
          var prefixSplit = prefix.split(' ');
          newExecutablePath = prefixSplit[0];
          for (int i = 1; i < prefixSplit.length; i++) {
            var current = prefixSplit[i];
            if (!current.isEmpty) newArguments.add(current);
          }
          newArguments.add(c.executable);
        }

        // Add any suffixes to the arguments of the original executable.
        var suffixSplit = suffix.split(' ');
        suffixSplit.forEach((e) {
          if (!e.isEmpty) newArguments.add(e);
        });

        newArguments.addAll(c.arguments);
        final newCommand = new Command(newExecutablePath, newArguments);
        newCommands.add(newCommand);
      }
      commands = newCommands;
    }
  }

  CommandOutput get lastCommandOutput {
    if (commandOutputs.length == 0) {
      throw new Exception("CommandOutputs is empty, maybe no command was run? ("
                          "displayName: '$displayName', "
                          "configurationString: '$configurationString')");
    }
    return commandOutputs[commands[commandOutputs.length - 1]];
  }

  int get timeout {
    if (expectedOutcomes.contains(SLOW)) {
      return configuration['timeout'] * SLOW_TIMEOUT_MULTIPLIER;
    } else {
      return configuration['timeout'];
    }
  }

  String get configurationString {
    final compiler = configuration['compiler'];
    final runtime = configuration['runtime'];
    final mode = configuration['mode'];
    final arch = configuration['arch'];
    final checked = configuration['checked'] ? '-checked' : '';
    return "$compiler-$runtime$checked ${mode}_$arch";
  }

  List<String> get batchRunnerArguments => ['-batch'];
  List<String> get batchTestArguments => commands.last.arguments;

  bool get usesWebDriver => TestUtils.usesWebDriver(configuration['runtime']);

  void completed() { completedHandler(this); }

  bool get isFlaky {
      if (expectedOutcomes.contains(SKIP)) {
        return false;
      }

      var flags = new Set.from(expectedOutcomes);
      flags..remove(TIMEOUT)
           ..remove(SLOW);
      return flags.contains(PASS) && flags.length > 1;
  }
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

  /**
   * True if this test is dependent on another test completing before it can
   * star (for example, we might need to depend on some other test completing
   * first).
   */
  bool waitingForOtherTest;

  /**
   * The set of test cases that wish to be notified when this test has
   * completed.
   */
  List<BrowserTestCase> observers;

  BrowserTestCase(displayName, commands, configuration, completedHandler,
      expectedOutcomes, info, isNegative, [this.waitingForOtherTest = false])
    : super(displayName, commands, configuration, completedHandler,
        expectedOutcomes, isNegative: isNegative, info: info) {
    numRetries = 2; // Allow two retries to compensate for flaky browser tests.
    observers = [];
  }

  List<String> get _lastArguments => commands.last.arguments;

  List<String> get batchRunnerArguments => [_lastArguments[0], '--batch'];

  List<String> get batchTestArguments => _lastArguments.sublist(1);

  /** Add a test case to listen for when this current test has completed. */
  void addObserver(BrowserTestCase testCase) {
    observers.add(testCase);
  }

  /**
   * Notify all of the test cases that are dependent on this one that they can
   * proceed.
   */
  void notifyObservers() {
    for (BrowserTestCase testCase in observers) {
      testCase.waitingForOtherTest = false;
    }
  }
}


/**
 * CommandOutput records the output of a completed command: the process's exit
 * code, the standard output and standard error, whether the process timed out,
 * and the time the process took to run.  It also contains a pointer to the
 * [TestCase] this is the output of.
 */
abstract class CommandOutput {
  factory CommandOutput.fromCase(TestCase testCase,
                                 Command command,
                                 int exitCode,
                                 bool incomplete,
                                 bool timedOut,
                                 List<int> stdout,
                                 List<int> stderr,
                                 Duration time,
                                 bool compilationSkipped) {
    return new CommandOutputImpl.fromCase(testCase,
                                          command,
                                          exitCode,
                                          incomplete,
                                          timedOut,
                                          stdout,
                                          stderr,
                                          time,
                                          compilationSkipped);
  }

  Command get command;

  bool get incomplete;

  String get result;

  bool get unexpectedOutput;

  bool get hasCrashed;

  bool get hasTimedOut;

  bool get didFail;

  bool requestRetry;

  Duration get time;

  int get exitCode;

  List<int> get stdout;

  List<int> get stderr;

  List<String> get diagnostics;

  bool get compilationSkipped;
}

class CommandOutputImpl implements CommandOutput {
  Command command;
  TestCase testCase;
  int exitCode;

  /// Records if all commands were run, true if they weren't.
  final bool incomplete;

  bool timedOut;
  bool failed = false;
  List<int> stdout;
  List<int> stderr;
  Duration time;
  List<String> diagnostics;
  bool compilationSkipped;

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

  // Don't call this constructor, call CommandOutput.fromCase() to
  // get a new TestOutput instance.
  CommandOutputImpl(TestCase this.testCase,
                    Command this.command,
                    int this.exitCode,
                    bool this.incomplete,
                    bool this.timedOut,
                    List<int> this.stdout,
                    List<int> this.stderr,
                    Duration this.time,
                    bool this.compilationSkipped) {
    testCase.commandOutputs[command] = this;
    diagnostics = [];
  }
  factory CommandOutputImpl.fromCase(TestCase testCase,
                                     Command command,
                                     int exitCode,
                                     bool incomplete,
                                     bool timedOut,
                                     List<int> stdout,
                                     List<int> stderr,
                                     Duration time,
                                     bool compilationSkipped) {
    if (testCase is BrowserTestCase) {
      return new BrowserCommandOutputImpl(testCase,
                                          command,
                                          exitCode,
                                          incomplete,
                                          timedOut,
                                          stdout,
                                          stderr,
                                          time,
                                          compilationSkipped);
    } else if (testCase.configuration['analyzer']) {
      return new AnalysisCommandOutputImpl(testCase,
                                           command,
                                           exitCode,
                                           timedOut,
                                           stdout,
                                           stderr,
                                           time,
                                           compilationSkipped);
    }
    return new CommandOutputImpl(testCase,
                                 command,
                                 exitCode,
                                 incomplete,
                                 timedOut,
                                 stdout,
                                 stderr,
                                 time,
                                 compilationSkipped);
  }

  String get result =>
      hasCrashed ? CRASH : (hasTimedOut ? TIMEOUT : (hasFailed ? FAIL : PASS));

  bool get unexpectedOutput => !testCase.expectedOutcomes.contains(result);

  bool get hasCrashed {
    // The Java dartc runner and dart2js exits with code 253 in case
    // of unhandled exceptions.
    if (exitCode == 253) return true;
    if (io.Platform.operatingSystem == 'windows') {
      // The VM uses std::abort to terminate on asserts.
      // std::abort terminates with exit code 3 on Windows.
      if (exitCode == 3) {
        return !timedOut;
      }
      // TODO(ricow): Remove this dirty hack ones we have a selenium
      // replacement.
      if (exitCode == CRASHING_BROWSER_EXITCODE) {
        return !timedOut;
      }
      // If a program receives an uncaught system exception, the program
      // terminates with the exception code as exit code.
      // The 0x3FFFFF00 mask here tries to determine if an exception indicates
      // a crash of the program.
      // System exception codes can be found in 'winnt.h', for example
      // "#define STATUS_ACCESS_VIOLATION  ((DWORD) 0xC0000005)"
      return (!timedOut && (exitCode < 0) && ((0x3FFFFF00 & exitCode) == 0));
    }
    return !timedOut && ((exitCode < 0));
  }

  bool get hasTimedOut => timedOut;

  bool get didFail {
    return (exitCode != 0 && !hasCrashed);
  }

  // Reverse result of a negative test.
  bool get hasFailed {
    // Always fail if a runtime-error is expected and compilation failed.
    if (testCase.info != null && testCase.info.hasRuntimeError && incomplete) {
      return true;
    }
    return testCase.isNegative ? !didFail : didFail;
  }

}

class BrowserCommandOutputImpl extends CommandOutputImpl {
  BrowserCommandOutputImpl(
      testCase,
      command,
      exitCode,
      incomplete,
      timedOut,
      stdout,
      stderr,
      time,
      compilationSkipped) :
    super(testCase,
          command,
          exitCode,
          incomplete,
          timedOut,
          stdout,
          stderr,
          time,
          compilationSkipped);

  bool get didFail {
    if (_failedBecauseOfMissingXDisplay) {
      return true;
    }

    if (command.expectedOutputFile != null) {
      // We are either doing a pixel test or a layout test with DumpRenderTree
      return _failedBecauseOfUnexpectedDRTOutput;
    }
    return _browserTestFailure;
  }

  bool get _failedBecauseOfMissingXDisplay {
    // Browser case:
    // If the browser test failed, it may have been because DumpRenderTree
    // and the virtual framebuffer X server didn't hook up, or DRT crashed with
    // a core dump. Sometimes DRT crashes after it has set the stdout to PASS,
    // so we have to do this check first.
    var stderrLines = decodeUtf8(super.stderr).split("\n");
    for (String line in stderrLines) {
      // TODO(kustermann,ricow): Issue: 7564
      // This seems to happen quite frequently, we need to figure out why.
      if (line.contains('Gtk-WARNING **: cannot open display') ||
          line.contains('Failed to run command. return code=1')) {
        // If we get the X server error, or DRT crashes with a core dump, retry
        // the test.
        if ((testCase as BrowserTestCase).numRetries > 0) {
          requestRetry = true;
        }
        print("Warning: Test failure because of missing XDisplay");
        return true;
      }
    }
    return false;
  }

  bool get _failedBecauseOfUnexpectedDRTOutput {
    /*
     * The output of DumpRenderTree is different for pixel tests than for
     * layout tests.
     *
     * On a pixel test, the DRT output has the following format
     *     ......
     *     ......
     *     Content-Length: ...\n
     *     <*png data>
     *     #EOF\n
     * So we need to get the byte-range of the png data first, before
     * comparing it with the content of the expected output file.
     *
     * On a layout tests, the DRT output is directly compared with the
     * content of the expected output.
     */
    var stdout = testCase.commandOutputs[command].stdout;
    var file = new io.File.fromPath(command.expectedOutputFile);
    if (file.existsSync()) {
      var bytesContentLength = "Content-Length:".codeUnits;
      var bytesNewLine = "\n".codeUnits;
      var bytesEOF = "#EOF\n".codeUnits;

      var expectedContent = file.readAsBytesSync();
      if (command.isPixelTest) {
        var startOfContentLength = findBytes(stdout, bytesContentLength);
        if (startOfContentLength >= 0) {
          var newLineAfterContentLength = findBytes(stdout,
                                                    bytesNewLine,
                                                    startOfContentLength);
          if (newLineAfterContentLength > 0) {
            var startPosition = newLineAfterContentLength +
                bytesNewLine.length;
            var endPosition = stdout.length - bytesEOF.length;

            return !areByteArraysEqual(expectedContent,
                                       0,
                                       stdout,
                                       startPosition,
                                       endPosition - startPosition);
          }
        }
        return true;
      } else {
        return !areByteArraysEqual(expectedContent, 0,
                                   stdout, 0,
                                   stdout.length);
      }
    }
    return true;
  }

  bool get _browserTestFailure {
    // Browser tests fail unless stdout contains
    // 'Content-Type: text/plain' followed by 'PASS'.
    bool has_content_type = false;
    var stdoutLines = decodeUtf8(super.stdout).split("\n");
    for (String line in stdoutLines) {
      switch (line) {
        case 'Content-Type: text/plain':
          has_content_type = true;
          break;
        case 'PASS':
          if (has_content_type) {
            if (exitCode != 0) {
              print("Warning: All tests passed, but exitCode != 0 "
                    "(${testCase.displayName})");
            }
            if (testCase.configuration['runtime'] == 'drt') {
              // TODO(kustermann/ricow): Issue: 7563
              // We should eventually get rid of this hack.
              return false;
            } else {
              return (exitCode != 0 && !hasCrashed);
            }
          }
          break;
      }
    }
    return true;
  }
}

// The static analyzer does not actually execute code, so
// the criteria for success now depend on the text sent
// to stderr.
class AnalysisCommandOutputImpl extends CommandOutputImpl {
  // An error line has 8 fields that look like:
  // ERROR|COMPILER|MISSING_SOURCE|file:/tmp/t.dart|15|1|24|Missing source.
  final int ERROR_LEVEL = 0;
  final int ERROR_TYPE = 1;
  final int FORMATTED_ERROR = 7;

  bool alreadyComputed = false;
  bool failResult;

  AnalysisCommandOutputImpl(testCase,
                            command,
                            exitCode,
                            timedOut,
                            stdout,
                            stderr,
                            time,
                            compilationSkipped) :
    super(testCase,
          command,
          exitCode,
          false,
          timedOut,
          stdout,
          stderr,
          time,
          compilationSkipped);

  bool get didFail {
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
    var stderrLines = decodeUtf8(super.stderr).split("\n");
    for (String line in stderrLines) {
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
    if (outcome == null) throw "outcome must not be null";
    if (outcome.contains('compile-time error') && errors.length > 0) {
      return true;
    } else if (outcome.contains('static type warning')
        && staticWarnings.length > 0) {
      return true;
    } else if (outcome.isEmpty
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
      hasFatalTypeErrors = testCase.info.hasFatalTypeErrors;
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
      diagnostics.add("Cannot have both @static-clean and /// static "
                      "type warning annotations.");
      return true;
    }

    if (isStaticClean && staticWarnings.length > 0) {
      diagnostics.add(
          "@static-clean annotation found but analyzer returned warnings.");
      return true;
    }

    if (numCompileTimeAnnotations > 0
        && numCompileTimeAnnotations < errors.length) {
      // Expected compile-time errors were not returned.
      // The test did not 'fail' in the way intended so don't return failed.
      diagnostics.add("Fewer compile time errors than annotated: "
          "$numCompileTimeAnnotations");
      return false;
    }

    if (numStaticTypeAnnotations > 0 || hasFatalTypeErrors) {
      // TODO(zundel): match up the annotation line numbers
      // with the reported error line numbers
      if (staticWarnings.length < numStaticTypeAnnotations) {
        diagnostics.add("Fewer static type warnings than annotated: "
            "$numStaticTypeAnnotations");
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
        field = new StringBuffer();
        continue;
      }
      field.write(c);
    }
    result.add(field.toString());
    return result;
  }
}

/**
 * A RunningProcess actually runs a test, getting the command lines from
 * its [TestCase], starting the test process (and first, a compilation
 * process if the TestCase is a [BrowserTestCase]), creating a timeout
 * timer, and recording the results in a new [CommandOutput] object, which it
 * attaches to the TestCase.  The lifetime of the RunningProcess is limited
 * to the time it takes to start the process, run the process, and record
 * the result; there are no pointers to it, so it should be available to
 * be garbage collected as soon as it is done.
 */
class RunningProcess {
  TestCase testCase;
  Command command;
  bool timedOut = false;
  DateTime startTime;
  Timer timeoutTimer;
  List<int> stdout = <int>[];
  List<int> stderr = <int>[];
  bool compilationSkipped = false;
  Completer<CommandOutput> completer;

  RunningProcess(TestCase this.testCase, Command this.command);

  Future<CommandOutput> start() {
    if (testCase.expectedOutcomes.contains(SKIP)) {
      throw "testCase.expectedOutcomes must not contain 'SKIP'.";
    }

    completer = new Completer<CommandOutput>();
    startTime = new DateTime.now();
    _runCommand();
    return completer.future;
  }

  void _runCommand() {
    command.outputIsUpToDate.then((bool isUpToDate) {
      if (isUpToDate) {
        compilationSkipped = true;
        _commandComplete(0);
      } else {
        var processOptions = _createProcessOptions();
        Future processFuture = io.Process.start(command.executable,
                                                command.arguments,
                                                processOptions);
        processFuture.then((io.Process process) {
          // Close stdin so that tests that try to block on input will fail.
          process.stdin.close();
          void timeoutHandler() {
            timedOut = true;
            if (process != null) {
              process.kill();
            }
          }
          process.exitCode.then(_commandComplete);
          _drainStream(process.stdout, stdout);
          _drainStream(process.stderr, stderr);
          timeoutTimer = new Timer(new Duration(seconds: testCase.timeout),
                                   timeoutHandler);
        }).catchError((e) {
          // TODO(floitsch): should we try to report the stacktrace?
          print("Process error:");
          print("  Command: $command");
          print("  Error: $e");
          _commandComplete(-1);
          return true;
        });
      }
    });
  }

  void _commandComplete(int exitCode) {
    if (timeoutTimer != null) {
      timeoutTimer.cancel();
    }
    var commandOutput = _createCommandOutput(command, exitCode);
    completer.complete(commandOutput);
  }

  CommandOutput _createCommandOutput(Command command, int exitCode) {
    var incomplete = command != testCase.commands.last;
    var commandOutput = new CommandOutput.fromCase(
        testCase,
        command,
        exitCode,
        incomplete,
        timedOut,
        stdout,
        stderr,
        new DateTime.now().difference(startTime),
        compilationSkipped);
    return commandOutput;
  }

  void _drainStream(Stream<List<int>> source, List<int> destination) {
    source.listen(destination.addAll);
  }

  io.ProcessOptions _createProcessOptions() {
    var baseEnvironment = command.environment != null ?
        command.environment : io.Platform.environment;
    io.ProcessOptions options = new io.ProcessOptions();
    options.environment = new Map<String, String>.from(baseEnvironment);
    options.environment['DART_CONFIGURATION'] =
        TestUtils.configurationDir(testCase.configuration);

    for (var excludedEnvironmentVariable in EXCLUDED_ENVIRONMENT_VARIABLES) {
      options.environment.remove(excludedEnvironmentVariable);
    }

    return options;
  }
}

class BatchRunnerProcess {
  Command _command;
  String _executable;
  List<String> _batchArguments;

  io.Process _process;
  Completer _stdoutCompleter;
  Completer _stderrCompleter;
  StreamSubscription<String> _stdoutSubscription;
  StreamSubscription<String> _stderrSubscription;
  Function _processExitHandler;

  TestCase _currentTest;
  List<int> _testStdout;
  List<int> _testStderr;
  String _status;
  DateTime _startTime;
  Timer _timer;

  bool _isWebDriver;

  BatchRunnerProcess(TestCase testCase) {
    _command = testCase.commands.last;
    _executable = testCase.commands.last.executable;
    _batchArguments = testCase.batchRunnerArguments;
    _isWebDriver = testCase.usesWebDriver;
  }

  bool get active => _currentTest != null;

  void startTest(TestCase testCase) {
    if (_currentTest != null) throw "_currentTest must be null.";
    _currentTest = testCase;
    _command = testCase.commands.last;
    if (_process == null) {
      // Start process if not yet started.
      _executable = testCase.commands.last.executable;
      _startProcess(() {
        doStartTest(testCase);
      });
    } else if (testCase.commands.last.executable != _executable) {
      // Restart this runner with the right executable for this test
      // if needed.
      _executable = testCase.commands.last.executable;
      _batchArguments = testCase.batchRunnerArguments;
      _processExitHandler = (_) {
        _startProcess(() {
          doStartTest(testCase);
        });
      };
      _process.kill();
    } else {
      doStartTest(testCase);
    }
  }

  Future terminate() {
    if (_process == null) return new Future.immediate(true);
    Completer completer = new Completer();
    Timer killTimer;
    _processExitHandler = (_) {
      if (killTimer != null) killTimer.cancel();
      completer.complete(true);
    };
    if (_isWebDriver) {
      // Use a graceful shutdown so our Selenium script can close
      // the open browser processes. On Windows, signals do not exist
      // and a kill is a hard kill.
      _process.stdin.writeln('--terminate');

      // In case the run_selenium process didn't close, kill it after 30s
      killTimer = new Timer(new Duration(seconds: 30), _process.kill);
    } else {
      _process.kill();
    }

    return completer.future;
  }

  void doStartTest(TestCase testCase) {
    _startTime = new DateTime.now();
    _testStdout = [];
    _testStderr = [];
    _status = null;
    _stdoutCompleter = new Completer();
    _stderrCompleter = new Completer();
    _timer = new Timer(new Duration(seconds: testCase.timeout),
                       _timeoutHandler);

    if (testCase.commands.last.environment != null) {
      print("Warning: command.environment != null, but we don't support custom "
            "environments for batch runner tests!");
    }

    var line = _createArgumentsLine(testCase.batchTestArguments);
    _process.stdin.write(line);
    _stdoutSubscription.resume();
    _stderrSubscription.resume();
    Future.wait([_stdoutCompleter.future,
                 _stderrCompleter.future]).then((_) => _reportResult());
  }

  String _createArgumentsLine(List<String> arguments) {
    return arguments.join(' ').concat('\n');
  }

  void _reportResult() {
    if (!active) return;
    // _status == '>>> TEST {PASS, FAIL, OK, CRASH, FAIL, TIMEOUT}'

    var outcome = _status.split(" ")[2];
    var exitCode = 0;
    if (outcome == "CRASH") exitCode = CRASHING_BROWSER_EXITCODE;
    if (outcome == "FAIL" || outcome == "TIMEOUT") exitCode = 1;
    new CommandOutput.fromCase(_currentTest,
                               _command,
                               exitCode,
                               false,
                               (outcome == "TIMEOUT"),
                               _testStdout,
                               _testStderr,
                               new DateTime.now().difference(_startTime),
                               false);
    var test = _currentTest;
    _currentTest = null;
    test.completed();
  }

  ExitCodeEvent makeExitHandler(String status) {
    void handler(int exitCode) {
      if (active) {
        if (_timer != null) _timer.cancel();
        _status = status;
        _stdoutSubscription.cancel();
        _stderrSubscription.cancel();
        _startProcess(_reportResult);
      } else {  // No active test case running.
        _process = null;
      }
    }
    return handler;
  }

  void _timeoutHandler() {
    _processExitHandler = makeExitHandler(">>> TEST TIMEOUT");
    _process.kill();
  }

  _startProcess(callback) {
    Future processFuture = io.Process.start(_executable, _batchArguments);
    processFuture.then((io.Process p) {
      _process = p;

      var _stdoutStream =
          _process.stdout
              .transform(new io.StringDecoder())
              .transform(new io.LineTransformer());
      _stdoutSubscription = _stdoutStream.listen((String line) {
        if (line.startsWith('>>> TEST')) {
          _status = line;
        } else if (line.startsWith('>>> BATCH')) {
          // ignore
        } else if (line.startsWith('>>> ')) {
          throw new Exception(
              'Unexpected command from ${testCase.configuration['compiler']} '
              'batch runner.');
        } else {
          _testStdout.addAll(encodeUtf8(line));
          _testStdout.addAll("\n".codeUnits);
        }
        if (_status != null) {
          _stdoutSubscription.pause();
          _timer.cancel();
          _stdoutCompleter.complete(null);
        }
      });
      _stdoutSubscription.pause();

      var _stderrStream =
          _process.stderr
              .transform(new io.StringDecoder())
              .transform(new io.LineTransformer());
      _stderrSubscription = _stderrStream.listen((String line) {
        if (line.startsWith('>>> EOF STDERR')) {
          _stderrSubscription.pause();
          _stderrCompleter.complete(null);
        } else {
          _testStderr.addAll(encodeUtf8(line));
          _testStderr.addAll("\n".codeUnits);
        }
      });
      _stderrSubscription.pause();

      _processExitHandler = makeExitHandler(">>> TEST CRASH");
      _process.exitCode.then((exitCode) {
        _processExitHandler(exitCode);
      });

      _process.stdin.done.catchError((err) {
        print('Error on batch runner input stream stdin');
        print('  Previous test\'s status: $_status');
        print('  Error: $err');
        throw err;
      });
      callback();
    }).catchError((e) {
      // TODO(floitsch): should we try to report the stacktrace?
      print("Process error:");
      print("  Command: $_executable ${_batchArguments.join(' ')}");
      print("  Error: $e");
      // If there is an error starting a batch process, chances are that
      // it will always fail. So rather than re-trying a 1000+ times, we
      // exit.
      io.exit(1);
      return true;
    });
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
  int _maxProcesses;
  int _numBrowserProcesses = 0;
  int _maxBrowserProcesses;
  int _numFailedTests = 0;
  bool _allTestsWereEnqueued = false;

  /** The number of tests we allow to actually fail before we stop retrying. */
  int _MAX_FAILED_NO_RETRY = 4;
  bool _verbose;
  bool _listTests;
  Function _allDone;
  Queue<TestCase> _tests;
  List<EventListener> _eventListener;

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
  io.Process _seleniumServer = null;

  /** True if we are in the process of starting the server. */
  bool _startingServer = false;

  /** True if we find that there is already a selenium jar running. */
  bool _seleniumAlreadyRunning = false;

  ProcessQueue(this._maxProcesses,
               this._maxBrowserProcesses,
               DateTime startTime,
               testSuites,
               this._eventListener,
               this._allDone,
               [bool verbose = false,
                bool listTests = false])
      : _verbose = verbose,
        _listTests = listTests,
        _tests = new Queue<TestCase>(),
        _batchProcesses = new Map<String, List<BatchRunnerProcess>>(),
        _testCache = new Map<String, List<TestInformation>>() {
    _runTests(testSuites);
  }

  /**
   * Perform any cleanup needed once all tests in a TestSuite have completed
   * and notify our progress indicator that we are done.
   */
  void _cleanupAndMarkDone() {
    _allDone();
    if (browserUsed != '' && _seleniumServer != null) {
      _seleniumServer.kill();
    }
    eventAllTestsDone();
  }

  void _checkDone() {
    if (_allTestsWereEnqueued && _tests.isEmpty && _numProcesses == 0) {
      _terminateBatchRunners().then((_) => _cleanupAndMarkDone());
    }
  }

  void _runTests(List<TestSuite> testSuites) {
    // FIXME: For some reason we cannot call this method on all test suites
    // in parallel.
    // If we do, not all tests get enqueued (if --arch=all was specified,
    // we don't get twice the number of tests [tested on -rvm -cnone])
    // Issue: 7927
    Iterator<TestSuite> iterator = testSuites.iterator;
    void enqueueNextSuite() {
      if (!iterator.moveNext()) {
        _allTestsWereEnqueued = true;
        eventAllTestsKnown();
        _checkDone();
      } else {
        iterator.current.forEachTest(_runTest, _testCache, enqueueNextSuite);
      }
    }
    enqueueNextSuite();
  }

  /**
   * True if we are using a browser + platform combination that needs the
   * Selenium server jar.
   */
  bool get _needsSelenium => (io.Platform.operatingSystem == 'macos' &&
      browserUsed == 'safari') || browserUsed == 'opera';

  /** True if the Selenium Server is ready to be used. */
  bool get _isSeleniumAvailable => _seleniumServer != null ||
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
      if (io.Platform.operatingSystem == 'windows') {
        cmd = 'tasklist';
        arg.add('/v');
      }

      Future processFuture = io.Process.start(cmd, arg);
      processFuture.then((io.Process p) {
        // Drain stderr to not leak resources.
        p.stderr.listen((_) {});
        final Stream<String> stdoutStringStream =
            p.stdout.transform(new io.StringDecoder())
                    .transform(new io.LineTransformer());
        stdoutStringStream.listen((String line) {
          var regexp = new RegExp(r".*selenium-server-standalone.*");
          if (regexp.hasMatch(line)) {
            _seleniumAlreadyRunning = true;
            resumeTesting();
          }
          if (!_isSeleniumAvailable) {
            _startSeleniumServer();
          }
        });
      }).catchError((e) {
      // TODO(floitsch): should we try to report the stacktrace?
        print("Error starting process:");
        print("  Command: $cmd ${arg.join(' ')}");
        print("  Error: $e");
        // TODO(ahe): How to report this as a test failure?
        io.exit(1);
        return true;
      });
    }
  }

  void _runTest(TestCase test) {
    if (test.usesWebDriver) {
      browserUsed = test.configuration['runtime'];
      if (_needsSelenium) _ensureSeleniumServerRunning();
    }
    eventTestAdded(test);
    _tests.add(test);
    _tryRunTest();
  }

  /**
   * Monitor the output of the Selenium server, to know when we are ready to
   * begin running tests.
   * source: Output(Stream) from the Java server.
   */
  void seleniumServerHandler(String line) {
    if (new RegExp(r".*Started.*Server.*").hasMatch(line) ||
        new RegExp(r"Exception.*Selenium is already running.*").hasMatch(
        line)) {
      resumeTesting();
    }
  }

  /**
   * For browser tests using Safari or Opera, we need to use the Selenium 1.0
   * Java server.
   */
  void _startSeleniumServer() {
    // Get the absolute path to the Selenium jar.
    String filePath = TestUtils.testScriptPath;
    String pathSep = io.Platform.pathSeparator;
    int index = filePath.lastIndexOf(pathSep);
    filePath = '${filePath.substring(0, index)}${pathSep}testing${pathSep}';
    new io.Directory(filePath).list().listen((io.FileSystemEntity fse) {
      if (fse is io.File) {
        String file = fse.path;
        if (new RegExp(r"selenium-server-standalone-.*\.jar").hasMatch(file)
            && _seleniumServer == null) {
          Future processFuture = io.Process.start('java', ['-jar', file]);
          processFuture.then((io.Process server) {
            _seleniumServer = server;
            // Heads up: there seems to an obscure data race of some form in
            // the VM between launching the server process and launching the
            // test tasks that disappears when you read IO (which is
            // convenient, since that is our condition for knowing that the
            // server is ready).
            Stream<String> stdoutStringStream =
                _seleniumServer.stdout.transform(new io.StringDecoder())
                .transform(new io.LineTransformer());
            Stream<String> stderrStringStream =
                _seleniumServer.stderr.transform(new io.StringDecoder())
                .transform(new io.LineTransformer());
            stdoutStringStream.listen(seleniumServerHandler);
            stderrStringStream.listen(seleniumServerHandler);
          }).catchError((e) {
            // TODO(floitsch): should we try to report the stacktrace?
            print("Process error:");
            print("  Command: java -jar $file");
            print("  Error: $e");
            // TODO(ahe): How to report this as a test failure?
            io.exit(1);
            return true;
          });
        }
      }
    });
  }

  Future _terminateBatchRunners() {
    var futures = new List();
    for (var runners in _batchProcesses.values) {
      for (var runner in runners) {
        futures.add(runner.terminate());
      }
    }
    // Change to Future.wait when updating binaries.
    return Future.wait(futures);
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
    if (_numProcesses < _maxProcesses && !_tests.isEmpty) {
      TestCase test = _tests.removeFirst();
      if (_listTests) {
        var fields = [test.displayName,
                      test.expectedOutcomes.join(','),
                      test.isNegative.toString()];
        fields.addAll(test.commands.last.arguments);
        print(fields.join('\t'));
        return;
      }
      if (test.usesWebDriver && _needsSelenium && !_isSeleniumAvailable || (test
          is BrowserTestCase && test.waitingForOtherTest)) {
        // The test is not yet ready to run. Put the test back in
        // the queue.  Avoid spin-polling by using a timeout.
        _tests.add(test);
        new Timer(new Duration(milliseconds: 100),
                  _tryRunTest);  // Don't lose a process.
        return;
      }
      // Before running any commands, we print out all commands if '--verbose'
      // was specified.
      if (_verbose && test.commandOutputs.length == 0) {
        int i = 1;
        if (test is BrowserTestCase) {
          // Additional command for rerunning the steps locally after the fact.
          var command =
            test.configuration["_servers_"].httpServerCommandline();
          print('$i. $command');
          i++;
        }
        for (Command command in test.commands) {
          print('$i. $command');
          i++;
        }
      }

      var isLastCommand =
          ((test.commands.length-1) == test.commandOutputs.length);
      var isBrowserCommand = isLastCommand && (test is BrowserTestCase);
      if (isBrowserCommand && _numBrowserProcesses == _maxBrowserProcesses) {
        // If there is no free browser runner, put it back into the queue.
        _tests.add(test);
        new Timer(new Duration(milliseconds: 100),
                  _tryRunTest);  // Don't lose a process.
        return;
      }

      eventStartTestCase(test);

      // Analyzer and browser test commands can be run by a [BatchRunnerProcess]
      var nextCommandIndex = test.commandOutputs.keys.length;
      var numberOfCommands = test.commands.length;

      var useBatchRunnerForAnalyzer =
          test.configuration['analyzer'] &&
          test.displayName != 'dartc/junit_tests';
      var isWebdriverCommand = nextCommandIndex == (numberOfCommands - 1) &&
                               test.usesWebDriver &&
                               !test.configuration['noBatch'];
      if (useBatchRunnerForAnalyzer || isWebdriverCommand) {
        TestCaseEvent oldCallback = test.completedHandler;
        void testCompleted(TestCase test_arg) {
          _numProcesses--;
          if (isBrowserCommand) {
            _numBrowserProcesses--;
          }
          eventFinishedTestCase(test_arg);
          if (test_arg is BrowserTestCase) test_arg.notifyObservers();
          oldCallback(test_arg);
          _tryRunTest();
        };
        test.completedHandler = testCompleted;
        _getBatchRunner(test).startTest(test);
      } else {
        // Once we've actually failed a test, technically, we wouldn't need to
        // bother retrying any subsequent tests since the bot is already red.
        // However, we continue to retry tests until we have actually failed
        // four tests (arbitrarily chosen) for more debugable output, so that
        // the developer doesn't waste his or her time trying to fix a bunch of
        // tests that appear to be broken but were actually just flakes that
        // didn't get retried because there had already been one failure.
        bool allowRetry = _MAX_FAILED_NO_RETRY > _numFailedTests;
        runNextCommandWithRetries(test, allowRetry).then((TestCase testCase) {
          _numProcesses--;
          if (isBrowserCommand) {
            _numBrowserProcesses--;
          }
          if (isTestCaseFinished(testCase)) {
            testCase.completed();
            eventFinishedTestCase(testCase);
            if (testCase is BrowserTestCase) testCase.notifyObservers();
          } else {
            _tests.addFirst(testCase);
          }
          _tryRunTest();
        });
      }

      _numProcesses++;
      if (isBrowserCommand) {
        _numBrowserProcesses++;
      }
    }
  }

  bool isTestCaseFinished(TestCase testCase) {
    var numberOfCommandOutputs = testCase.commandOutputs.keys.length;
    var numberOfCommands = testCase.commands.length;

    var lastCommandCompleted = (numberOfCommandOutputs == numberOfCommands);
    var lastCommandOutput = testCase.lastCommandOutput;
    var lastCommand = lastCommandOutput.command;
    var timedOut = lastCommandOutput.hasTimedOut;
    var nonZeroExitCode = lastCommandOutput.exitCode != 0;
    // NOTE: If this was the last command or there was unexpected output
    // we're done with the test.
    // Otherwise we need to enqueue it again into the test queue.
    if (lastCommandCompleted || timedOut || nonZeroExitCode) {
      var verbose = testCase.configuration['verbose'];
      if (lastCommandOutput.unexpectedOutput && verbose != null && verbose) {
        print(testCase.displayName);
        print("stderr:");
        print(decodeUtf8(lastCommandOutput.stderr));
        if (!lastCommand.isPixelTest) {
          print("stdout:");
          print(decodeUtf8(lastCommandOutput.stdout));
        } else {
          print("");
          print("DRT pixel test failed! stdout is not printed because it "
                "contains binary data!");
        }
      }
      return true;
    } else {
      return false;
    }
  }

  Future runNextCommandWithRetries(TestCase testCase, bool allowRetry) {
    var completer = new Completer();

    var nextCommandIndex = testCase.commandOutputs.keys.length;
    var numberOfCommands = testCase.commands.length;
    if (nextCommandIndex >= numberOfCommands) {
      throw "nextCommandIndex must be less than numberOfCommands";
    }
    var command = testCase.commands[nextCommandIndex];
    var isLastCommand = nextCommandIndex == (numberOfCommands - 1);

    void runCommand() {
      var runningProcess = new RunningProcess(testCase, command);
      runningProcess.start().then((CommandOutput commandOutput) {
        if (isLastCommand) {
          // NOTE: We need to call commandOutput.unexpectedOutput here.
          // Calling this getter may result in the side-effect, that
          // commandOutput.requestRetry is set to true.
          // (BrowserCommandOutputImpl._failedBecauseOfMissingXDisplay
          // does that for example)
          // TODO(ricow/kustermann): Issue 8206
          var unexpectedOutput = commandOutput.unexpectedOutput;
          if (allowRetry && testCase.usesWebDriver
              && unexpectedOutput
              && (testCase as BrowserTestCase).numRetries > 0) {
            // Selenium tests can be flaky. Try rerunning.
            commandOutput.requestRetry = true;
          }
        }
        if (commandOutput.requestRetry) {
          commandOutput.requestRetry = false;
          (testCase as BrowserTestCase).numRetries--;
          DebugLogger.warning("Rerunning Test: ${testCase.displayName} "
                              "(${(testCase as BrowserTestCase).numRetries} "
                              "attempt(s) remains) [cmd:$command]");
          runCommand();
        } else {
          completer.complete(testCase);
        }
      });
    }
    runCommand();

    return completer.future;
  }

  void eventStartTestCase(TestCase testCase) {
    for (var listener in _eventListener) {
      listener.start(testCase);
    }
  }

  void eventFinishedTestCase(TestCase testCase) {
    if (testCase.lastCommandOutput.unexpectedOutput) {
      _numFailedTests++;
    }
    for (var listener in _eventListener) {
      listener.done(testCase);
    }
  }

  void eventTestAdded(TestCase testCase) {
    for (var listener in _eventListener) {
      listener.testAdded();
    }
  }

  void eventAllTestsKnown() {
    for (var listener in _eventListener) {
      listener.allTestsKnown();
    }
  }

  void eventAllTestsDone() {
    for (var listener in _eventListener) {
      listener.allDone();
    }
  }
}

