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
import "dart:convert" show LineSplitter, UTF8;
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import "dart:io" as io;
import "dart:isolate";
import "dart:math" as math;
import 'dependency_graph.dart' as dgraph;
import "browser_controller.dart";
import "http_server.dart" as http_server;
import "status_file_parser.dart";
import "test_progress.dart";
import "test_suite.dart";
import "utils.dart";
import 'record_and_replay.dart';

const int CRASHING_BROWSER_EXITCODE = -10;
const int SLOW_TIMEOUT_MULTIPLIER = 4;

const MESSAGE_CANNOT_OPEN_DISPLAY = 'Gtk-WARNING **: cannot open display';
const MESSAGE_FAILED_TO_RUN_COMMAND = 'Failed to run command. return code=1';

typedef void TestCaseEvent(TestCase testCase);
typedef void ExitCodeEvent(int exitCode);
typedef void EnqueueMoreWork(ProcessQueue queue);

// Some IO tests use these variables and get confused if the host environment
// variables are inherited so they are excluded.
const List<String> EXCLUDED_ENVIRONMENT_VARIABLES =
    const ['http_proxy', 'https_proxy', 'no_proxy',
           'HTTP_PROXY', 'HTTPS_PROXY', 'NO_PROXY'];


/** A command executed as a step in a test case. */
class Command {
  /** Path to the executable of this command. */
  String executable;

  /** The actual command line that will be executed. */
  String commandLine;

  /** A descriptive name for this command. */
  String displayName;

  /** Command line arguments to the executable. */
  List<String> arguments;

  /** Environment for the command */
  Map<String, String> environmentOverrides;

  /** Number of times this command *can* be retried */
  int get maxNumRetries => 2;

  // We compute the Command.hashCode lazily and cache it here, since it might
  // be expensive to compute (and hashCode is called often).
  int _cachedHashCode;

  Command._(this.displayName, this.executable,
            this.arguments, String configurationDir,
            [this.environmentOverrides = null]) {
    if (io.Platform.operatingSystem == 'windows') {
      // Windows can't handle the first command if it is a .bat file or the like
      // with the slashes going the other direction.
      // TODO(efortuna): Remove this when fixed (Issue 1306).
      executable = executable.replaceAll('/', '\\');
    }
    var quotedArguments = [];
    quotedArguments.add(escapeCommandLineArgument(executable));
    quotedArguments.addAll(arguments.map(escapeCommandLineArgument));
    commandLine = quotedArguments.join(' ');

    if (configurationDir != null) {
      if (environmentOverrides == null) {
        environmentOverrides = new Map<String, String>();
      }
      environmentOverrides['DART_CONFIGURATION'] = configurationDir;
    }
  }

  int get hashCode {
    if (_cachedHashCode == null) {
      var builder = new HashCodeBuilder();
      _buildHashCode(builder);
      _cachedHashCode = builder.value;
    }
    return _cachedHashCode;
  }

  operator ==(other) {
    if (other is Command) {
      return identical(this, other) || _equal(other as Command);
    }
    return false;
  }

  void _buildHashCode(HashCodeBuilder builder) {
    builder.add(executable);
    builder.add(commandLine);
    builder.add(displayName);
    for (var object in arguments) builder.add(object);
    if (environmentOverrides != null) {
      for (var key in environmentOverrides.keys) {
        builder.add(key);
        builder.add(environmentOverrides[key]);
      }
    }
  }

  bool _equal(Command other) {
    if (hashCode != other.hashCode ||
        executable != other.executable ||
        commandLine != other.commandLine ||
        displayName != other.displayName ||
        arguments.length != other.arguments.length) {
      return false;
    }

    if ((environmentOverrides != other.environmentOverrides) &&
        (environmentOverrides == null || other.environmentOverrides == null)) {
      return false;
    }

    if (environmentOverrides != null &&
        environmentOverrides.length != other.environmentOverrides.length) {
      return false;
    }

    for (var i = 0; i < arguments.length; i++) {
      if (arguments[i] != other.arguments[i]) return false;
    }

    if (environmentOverrides != null) {
      for (var key in environmentOverrides.keys) {
        if (!other.environmentOverrides.containsKey(key) ||
            environmentOverrides[key] != other.environmentOverrides[key]) {
          return false;
        }
      }
    }
    return true;
  }

  String toString() => commandLine;

  Future<bool> get outputIsUpToDate => new Future.value(false);
  Path get expectedOutputFile => null;
  bool get isPixelTest => false;
}

class CompilationCommand extends Command {
  String _outputFile;
  bool _neverSkipCompilation;
  List<Uri> _bootstrapDependencies;

  CompilationCommand._(String displayName,
                       this._outputFile,
                       this._neverSkipCompilation,
                       List<String> bootstrapDependencies,
                       String executable,
                       List<String> arguments,
                       String configurationDir)
      : super._(displayName, executable, arguments, configurationDir) {
    // We sort here, so we can do a fast hashCode/operator==
    _bootstrapDependencies = new List.from(bootstrapDependencies);
    _bootstrapDependencies.sort();
  }

  Future<bool> get outputIsUpToDate {
    if (_neverSkipCompilation) return new Future.value(false);

    Future<List<Uri>> readDepsFile(String path) {
      var file = new io.File(new Path(path).toNativePath());
      if (!file.existsSync()) {
        return new Future.value(null);
      }
      return file.readAsLines().then((List<String> lines) {
        var dependencies = new List<Uri>();
        for (var line in lines) {
          line = line.trim();
          if (line.length > 0) {
            dependencies.add(Uri.parse(line));
          }
        }
        return dependencies;
      });
    }

    return readDepsFile("$_outputFile.deps").then((dependencies) {
      if (dependencies != null) {
        dependencies.addAll(_bootstrapDependencies);
        var jsOutputLastModified = TestUtils.lastModifiedCache.getLastModified(
            new Uri(scheme: 'file', path: _outputFile));
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

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(_outputFile);
    builder.add(_neverSkipCompilation);
    for (var uri in _bootstrapDependencies) builder.add(uri);
  }

  bool _equal(Command other) {
    if (other is CompilationCommand &&
        super._equal(other) &&
        _outputFile == other._outputFile &&
        _neverSkipCompilation == other._neverSkipCompilation &&
        _bootstrapDependencies.length == other._bootstrapDependencies.length) {
      for (var i = 0; i < _bootstrapDependencies.length; i++) {
        if (_bootstrapDependencies[i] != other._bootstrapDependencies[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

class ContentShellCommand extends Command {
  /**
   * If [expectedOutputPath] is set, the output of content shell is compared
   * with the content of [expectedOutputPath].
   * This is used for example for pixel tests, where [expectedOutputPath] points
   * to a *png file.
   */
  Path expectedOutputPath;

  ContentShellCommand._(String executable,
                        String htmlFile,
                        List<String> options,
                        List<String> dartFlags,
                        Path this.expectedOutputPath,
                        String configurationDir)
      : super._("content_shell",
               executable,
               _getArguments(options, htmlFile),
               configurationDir,
               _getEnvironment(dartFlags));

  static Map _getEnvironment(List<String> dartFlags) {
    var needDartFlags = dartFlags != null && dartFlags.length > 0;

    var env = null;
    if (needDartFlags) {
      env = new Map<String, String>();
      env['DART_FLAGS'] = dartFlags.join(" ");
    }

    return env;
  }

  static List<String> _getArguments(List<String> options, String htmlFile) {
    var arguments = new List.from(options);
    arguments.add(htmlFile);
    return arguments;
  }

  Path get expectedOutputFile => expectedOutputPath;
  bool get isPixelTest => (expectedOutputFile != null &&
                           expectedOutputFile.filename.endsWith(".png"));

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(expectedOutputPath.toString());
  }

  bool _equal(Command other) {
    return
        other is ContentShellCommand &&
        super._equal(other) &&
        expectedOutputPath.toString() == other.expectedOutputPath.toString();
  }

  int get maxNumRetries => 3;
}

class BrowserTestCommand extends Command {
  final String browser;
  final String url;

  BrowserTestCommand._(String _browser,
                       this.url,
                       String executable,
                       List<String> arguments,
                       String configurationDir)
      : super._(_browser, executable, arguments, configurationDir),
        browser = _browser;

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(browser);
    builder.add(url);
  }

  bool _equal(Command other) {
    return
        other is BrowserTestCommand &&
        super._equal(other) &&
        browser == other.browser &&
        url == other.url;
  }
}

class SeleniumTestCommand extends Command {
  final String browser;
  final String url;

  SeleniumTestCommand._(String _browser,
                        this.url,
                        String executable,
                        List<String> arguments,
                        String configurationDir)
      : super._(_browser, executable, arguments, configurationDir),
        browser = _browser;

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(browser);
    builder.add(url);
  }

  bool _equal(Command other) {
    return
        other is SeleniumTestCommand &&
        super._equal(other) &&
        browser == other.browser &&
        url == other.url;
  }
}

class AnalysisCommand extends Command {
  final String flavor;

  AnalysisCommand._(this.flavor,
                    String displayName,
                    String executable,
                    List<String> arguments,
                    String configurationDir)
      : super._(displayName, executable, arguments, configurationDir);

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(flavor);
  }

  bool _equal(Command other) {
    return
        other is AnalysisCommand &&
        super._equal(other) &&
        flavor == other.flavor;
  }
}

class VmCommand extends Command {
  VmCommand._(String executable,
              List<String> arguments,
              String configurationDir)
      : super._("vm", executable, arguments, configurationDir);
}

class JSCommandlineCommand extends Command {
  JSCommandlineCommand._(String displayName,
                         String executable,
                         List<String> arguments,
                         String configurationDir,
                         [Map<String, String> environmentOverrides = null])
      : super._(displayName,
                executable,
                arguments,
                configurationDir,
                environmentOverrides);
}

class CommandBuilder {
  static final instance = new CommandBuilder._();

  final _cachedCommands = new Map<Command, Command>();

  CommandBuilder._();

  ContentShellCommand getContentShellCommand(String executable,
                                             String htmlFile,
                                             List<String> options,
                                             List<String> dartFlags,
                                             Path expectedOutputPath,
                                             String configurationDir) {
    ContentShellCommand command = new ContentShellCommand._(
        executable, htmlFile, options, dartFlags, expectedOutputPath,
        configurationDir);
    return _getUniqueCommand(command);
  }

  BrowserTestCommand getBrowserTestCommand(String browser,
                                           String url,
                                           String executable,
                                           List<String> arguments,
                                           String configurationDir) {
    var command = new BrowserTestCommand._(
        browser, url, executable, arguments, configurationDir);
    return _getUniqueCommand(command);
  }

  SeleniumTestCommand getSeleniumTestCommand(String browser,
                                             String url,
                                             String executable,
                                             List<String> arguments,
                                             String configurationDir) {
    var command = new SeleniumTestCommand._(
        browser, url, executable, arguments, configurationDir);
    return _getUniqueCommand(command);
  }

  CompilationCommand getCompilationCommand(String displayName,
                                           outputFile,
                                           neverSkipCompilation,
                                           List<String> bootstrapDependencies,
                                           String executable,
                                           List<String> arguments,
                                           String configurationDir) {
    var command =
        new CompilationCommand._(displayName, outputFile, neverSkipCompilation,
                                 bootstrapDependencies, executable, arguments,
                                 configurationDir);
    return _getUniqueCommand(command);
  }

  AnalysisCommand getAnalysisCommand(
      String displayName, executable, arguments, String configurationDir,
      {String flavor: 'dartanalyzer'}) {
    var command = new AnalysisCommand._(
        flavor, displayName, executable, arguments, configurationDir);
    return _getUniqueCommand(command);
  }

  VmCommand getVmCommand(String executable,
                         List<String> arguments,
                         String configurationDir) {
    var command = new VmCommand._(executable, arguments, configurationDir);
    return _getUniqueCommand(command);
  }

  Command getJSCommandlineCommand(String displayName, executable, arguments,
                     String configurationDir, [environment = null]) {
    var command = new JSCommandlineCommand._(displayName, executable, arguments,
                                             configurationDir, environment);
    return _getUniqueCommand(command);
  }

  Command getCommand(String displayName, executable, arguments,
                     String configurationDir, [environment = null]) {
    var command = new Command._(displayName, executable, arguments,
                                configurationDir, environment);
    return _getUniqueCommand(command);
  }

  Command _getUniqueCommand(Command command) {
    // All Command classes have hashCode/operator==, so we check if this command
    // has already been build, if so we return the cached one, otherwise we
    // store the one given as [command] argument.
    var cachedCommand = _cachedCommands[command];
    if (cachedCommand != null) {
      return cachedCommand;
    }
    _cachedCommands[command] = command;
    return command;
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
 * The output information is stored in a [CommandOutput] instance contained
 * in TestCase.commandOutputs. The last CommandOutput instance is responsible
 * for evaluating if the test has passed, failed, crashed, or timed out, and the
 * TestCase has information about what the expected result of the test should
 * be.
 *
 * The TestCase has a callback function, [completedHandler], that is run when
 * the test is completed.
 */
class TestCase extends UniqueObject {
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
  Set<Expectation> expectedOutcomes;
  TestInformation info;

  TestCase(this.displayName,
           this.commands,
           this.configuration,
           this.expectedOutcomes,
           {this.isNegative: false,
            this.info: null}) {
    if (!isNegative) {
      this.isNegative = displayName.contains("negative_test");
    }
  }

  bool get unexpectedOutput {
    var outcome = lastCommandOutput.result(this);
    return !expectedOutcomes.any((expectation) {
      return outcome.canBeOutcomeOf(expectation);
    });
  }

  Expectation get result => lastCommandOutput.result(this);

  CommandOutput get lastCommandOutput {
    if (commandOutputs.length == 0) {
      throw new Exception("CommandOutputs is empty, maybe no command was run? ("
                          "displayName: '$displayName', "
                          "configurationString: '$configurationString')");
    }
    return commandOutputs[commands[commandOutputs.length - 1]];
  }

  int get timeout {
    if (expectedOutcomes.contains(Expectation.SLOW)) {
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

  List<String> get batchTestArguments => commands.last.arguments;

  bool get usesWebDriver => TestUtils.usesWebDriver(configuration['runtime']);

  bool get isFlaky {
      if (expectedOutcomes.contains(Expectation.SKIP) ||
          expectedOutcomes.contains(Expectation.SKIP_BY_DESIGN)) {
        return false;
      }

      return expectedOutcomes
        .where((expectation) => !expectation.isMetaExpectation).length > 1;
  }

  bool get isFinished {
    return !lastCommandOutput.successful ||
           commands.length == commandOutputs.length;
  }
}


/**
 * BrowserTestCase has an extra compilation command that is run in a separate
 * process, before the regular test is run as in the base class [TestCase].
 * If the compilation command fails, then the rest of the test is not run.
 */
class BrowserTestCase extends TestCase {

  BrowserTestCase(displayName, commands, configuration,
                  expectedOutcomes, info, isNegative, this._testingUrl)
    : super(displayName, commands, configuration,
            expectedOutcomes, isNegative: isNegative, info: info);

  String _testingUrl;

  String get testingUrl => _testingUrl;
}

class UnittestSuiteMessagesMixin {
  bool _isAsyncTest(String testOutput) {
    return testOutput.contains("unittest-suite-wait-for-done");
  }

  bool _isAsyncTestSuccessfull(String testOutput) {
    return testOutput.contains("unittest-suite-success");
  }

  Expectation _negateOutcomeIfIncompleteAsyncTest(Expectation outcome,
                                                  String testOutput) {
    // If this is an asynchronous test and the asynchronous operation didn't
    // complete successfully, it's outcome is Expectation.FAIL.
    // TODO: maybe we should introduce a AsyncIncomplete marker or so
    if (outcome == Expectation.PASS) {
      if (_isAsyncTest(testOutput) &&
          !_isAsyncTestSuccessfull(testOutput)) {
        return Expectation.FAIL;
      }
    }
    return outcome;
  }
}

/**
 * CommandOutput records the output of a completed command: the process's exit
 * code, the standard output and standard error, whether the process timed out,
 * and the time the process took to run.  It also contains a pointer to the
 * [TestCase] this is the output of.
 */
abstract class CommandOutput {
  Command get command;

  Expectation result(TestCase testCase);

  bool get hasCrashed;

  bool get hasTimedOut;

  bool didFail(testcase);

  bool hasFailed(TestCase testCase);

  bool get canRunDependendCommands;

  bool get successful; // otherwise we might to retry running

  Duration get time;

  int get exitCode;

  List<int> get stdout;

  List<int> get stderr;

  List<String> get diagnostics;

  bool get compilationSkipped;
}

class CommandOutputImpl extends UniqueObject implements CommandOutput {
  Command command;
  int exitCode;

  bool timedOut;
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

  // TODO(kustermann): Remove testCase from this class.
  CommandOutputImpl(Command this.command,
                    int this.exitCode,
                    bool this.timedOut,
                    List<int> this.stdout,
                    List<int> this.stderr,
                    Duration this.time,
                    bool this.compilationSkipped) {
    diagnostics = [];
  }

  Expectation result(TestCase testCase) {
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;
    return hasFailed(testCase) ? Expectation.FAIL : Expectation.PASS;
  }

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

  bool didFail(TestCase testCase) {
    return (exitCode != 0 && !hasCrashed);
  }

  bool get canRunDependendCommands {
    // FIXME(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  bool get successful {
    // FIXME(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  // Reverse result of a negative test.
  bool hasFailed(TestCase testCase) {
    return testCase.isNegative ? !didFail(testCase) : didFail(testCase);
  }

  Expectation _negateOutcomeIfNegativeTest(Expectation outcome,
                                           bool isNegative) {
    if (!isNegative) return outcome;

    if (outcome.canBeOutcomeOf(Expectation.FAIL)) {
      return Expectation.PASS;
    }
    return Expectation.FAIL;
  }
}

class BrowserCommandOutputImpl extends CommandOutputImpl {
  bool _failedBecauseOfMissingXDisplay;

  BrowserCommandOutputImpl(
      command,
      exitCode,
      timedOut,
      stdout,
      stderr,
      time,
      compilationSkipped) :
    super(command,
          exitCode,
          timedOut,
          stdout,
          stderr,
          time,
          compilationSkipped) {
    _failedBecauseOfMissingXDisplay = _didFailBecauseOfMissingXDisplay();
    if (_failedBecauseOfMissingXDisplay) {
      DebugLogger.warning("Warning: Test failure because of missing XDisplay");
      // If we get the X server error, or DRT crashes with a core dump, retry
      // the test.
    }
  }

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    var outcome = _getOutcome();

    if (testCase.info != null && testCase.info.hasRuntimeError) {
      if (!outcome.canBeOutcomeOf(Expectation.RUNTIME_ERROR)) {
        return Expectation.MISSING_RUNTIME_ERROR;
      }
    }

    if (testCase.isNegative) {
      if (outcome.canBeOutcomeOf(Expectation.FAIL)) return Expectation.PASS;
      return Expectation.FAIL;
    }
    return outcome;
  }

  bool get successful => canRunDependendCommands;

  bool get canRunDependendCommands {
    // We cannot rely on the exit code of content_shell as a method to determine
    // if we were successful or not.
    return super.canRunDependendCommands && !didFail(null);
  }

  Expectation _getOutcome() {
    if (_failedBecauseOfMissingXDisplay) {
      return Expectation.FAIL;
    }

    if (command.expectedOutputFile != null) {
      // We are either doing a pixel test or a layout test with content shell
      if (_failedBecauseOfUnexpectedDRTOutput) {
        return Expectation.FAIL;
      }
    }
    if (_browserTestFailure) {
      return Expectation.RUNTIME_ERROR;
    }
    return Expectation.PASS;
  }

  bool _didFailBecauseOfMissingXDisplay() {
    // Browser case:
    // If the browser test failed, it may have been because content shell
    // and the virtual framebuffer X server didn't hook up, or it crashed with
    // a core dump. Sometimes content shell crashes after it has set the stdout
    // to PASS, so we have to do this check first.
    var stderrLines = decodeUtf8(super.stderr).split("\n");
    for (String line in stderrLines) {
      // TODO(kustermann,ricow): Issue: 7564
      // This seems to happen quite frequently, we need to figure out why.
      if (line.contains(MESSAGE_CANNOT_OPEN_DISPLAY) ||
          line.contains(MESSAGE_FAILED_TO_RUN_COMMAND)) {
        return true;
      }
    }
    return false;
  }

  bool get _failedBecauseOfUnexpectedDRTOutput {
    /*
     * The output of content shell is different for pixel tests than for
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
    var file = new io.File(command.expectedOutputFile.toNativePath());
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
              print("Warning: All tests passed, but exitCode != 0 ($this)");
            }
            return (exitCode != 0 && !hasCrashed);
          }
          break;
      }
    }
    return true;
  }
}

class HTMLBrowserCommandOutputImpl extends BrowserCommandOutputImpl {
 HTMLBrowserCommandOutputImpl(
      command,
      exitCode,
      timedOut,
      stdout,
      stderr,
      time,
      compilationSkipped) :
    super(command,
          exitCode,
          timedOut,
          stdout,
          stderr,
          time,
          compilationSkipped);

  bool get _browserTestFailure {
    // We should not need to convert back and forward.
    var output = decodeUtf8(super.stdout);
    if (output.contains("FAIL")) return true;
    return !output.contains("PASS");
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

  // TODO(kustermann): Remove testCase from this class
  AnalysisCommandOutputImpl(command,
                            exitCode,
                            timedOut,
                            stdout,
                            stderr,
                            time,
                            compilationSkipped) :
    super(command,
          exitCode,
          timedOut,
          stdout,
          stderr,
          time,
          compilationSkipped);

  bool didFail(TestCase testCase) {
    if (!alreadyComputed) {
      failResult = _didFail(testCase);
      alreadyComputed = true;
    }
    return failResult;
  }

  bool _didFail(TestCase testCase) {
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
        staticWarnings.add(fields[FORMATTED_ERROR]);
      }
      // OK to Skip error output that doesn't match the machine format
    }
    // FIXME(kustermann): This is wrong, we should give the expectations
    // to Command
    if (testCase.info != null
        && testCase.info.optionsFromFile['isMultitest']) {
      return _didMultitestFail(testCase, errors, staticWarnings);
    }
    return _didStandardTestFail(testCase, errors, staticWarnings);
  }

  bool _didMultitestFail(TestCase testCase, List errors, List staticWarnings) {
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

  bool _didStandardTestFail(TestCase testCase, List errors, List staticWarnings) {
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
      // If the analyzer has warnings it will exit 1.
      // We should reconsider how we do this once we have landed a dart
      // only version of the analyzer for stable use (as in not run in batch
      // mode).
      if (!hasFatalTypeErrors && exitCode != 0 && staticWarnings.length == 0) {
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

    if (isStaticClean && (errors.isNotEmpty || staticWarnings.isNotEmpty)) {
      diagnostics.add(
          "@static-clean annotation found but analyzer returned problems.");
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

class VmCommandOutputImpl extends CommandOutputImpl
                          with UnittestSuiteMessagesMixin {
  static const DART_VM_EXITCODE_COMPILE_TIME_ERROR = 254;
  static const DART_VM_EXITCODE_UNCAUGHT_EXCEPTION = 255;

  VmCommandOutputImpl(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    // Multitests are handled specially
    if (testCase.info != null) {
      if (testCase.info.hasCompileError) {
        if (exitCode == DART_VM_EXITCODE_COMPILE_TIME_ERROR) {
          return Expectation.PASS;
        }

        // We're not as strict, if the exitCode indicated an uncaught exception
        // we say it passed nonetheless
        // TODO(kustermann): As soon as the VM team makes sure we get correct
        // exit codes, we should remove this.
        if (exitCode == DART_VM_EXITCODE_UNCAUGHT_EXCEPTION) {
          return Expectation.PASS;
        }

        return Expectation.MISSING_COMPILETIME_ERROR;
      }
      if (testCase.info.hasRuntimeError) {
        // TODO(kustermann): Do we consider a "runtimeError" only an uncaught
        // exception or does any nonzero exit code fullfil this requirement?
        if (exitCode != 0) {
          return Expectation.PASS;
        }
        return Expectation.MISSING_RUNTIME_ERROR;
      }
    }

    // The actual outcome depends on the exitCode
    Expectation outcome;
    if (exitCode == DART_VM_EXITCODE_COMPILE_TIME_ERROR) {
      outcome = Expectation.COMPILETIME_ERROR;
    } else if (exitCode == DART_VM_EXITCODE_UNCAUGHT_EXCEPTION) {
      outcome = Expectation.RUNTIME_ERROR;
    } else if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      outcome = Expectation.FAIL;
    } else {
      outcome = Expectation.PASS;
    }
    outcome = _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class CompilationCommandOutputImpl extends CommandOutputImpl {
  static const DART2JS_EXITCODE_CRASH = 253;

  CompilationCommandOutputImpl(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false);

  Expectation result(TestCase testCase) {
    // Handle general crash/timeout detection.
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    // Handle dart2js/dart2dart specific crash detection
    if (exitCode == DART2JS_EXITCODE_CRASH ||
        exitCode == VmCommandOutputImpl.DART_VM_EXITCODE_COMPILE_TIME_ERROR ||
        exitCode == VmCommandOutputImpl.DART_VM_EXITCODE_UNCAUGHT_EXCEPTION) {
      return Expectation.CRASH;
    }

    // Multitests are handled specially
    if (testCase.info != null) {
      if (testCase.info.hasCompileError) {
        // Nonzero exit code of the compiler means compilation failed
        // TODO(kustermann): Do we have a special exit code in that case???
        if (exitCode != 0) {
          return Expectation.PASS;
        }
        return Expectation.MISSING_COMPILETIME_ERROR;
      }

      // TODO(kustermann): This is a hack, remove it
      if (testCase.info.hasRuntimeError && testCase.commands.length > 1) {
        // We expected to run the test, but we got an compile time error.
        // If the compilation succeeded, we wouldn't be in here!
        assert(exitCode != 0);
        return Expectation.COMPILETIME_ERROR;
      }
    }

    Expectation outcome =
        exitCode == 0 ? Expectation.PASS : Expectation.COMPILETIME_ERROR;
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class JsCommandlineOutputImpl extends CommandOutputImpl
                              with UnittestSuiteMessagesMixin {
  JsCommandlineOutputImpl(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    if (testCase.info != null && testCase.info.hasRuntimeError) {
      if (exitCode != 0) return Expectation.PASS;
      return Expectation.MISSING_RUNTIME_ERROR;
    }

    var outcome = exitCode == 0 ? Expectation.PASS : Expectation.RUNTIME_ERROR;
    outcome = _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

CommandOutput createCommandOutput(Command command,
                                  int exitCode,
                                  bool timedOut,
                                  List<int> stdout,
                                  List<int> stderr,
                                  Duration time,
                                  bool compilationSkipped) {
  if (command is ContentShellCommand) {
    return new BrowserCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr,
        time, compilationSkipped);
  } else if (command is BrowserTestCommand) {
    return new HTMLBrowserCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr,
        time, compilationSkipped);
  } else if (command is SeleniumTestCommand) {
    return new BrowserCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr,
        time, compilationSkipped);
  } else if (command is AnalysisCommand) {
    return new AnalysisCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr,
        time, compilationSkipped);
  } else if (command is VmCommand) {
    return new VmCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time);
  } else if (command is CompilationCommand) {
    return new CompilationCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time);
  } else if (command is JSCommandlineCommand) {
    return new JsCommandlineOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time);
  }

  return new CommandOutputImpl(
      command, exitCode, timedOut, stdout, stderr,
      time, compilationSkipped);
}


/** Modifies the --timeout=XX parameter passed to run_selenium.py */
List<String> _modifySeleniumTimeout(List<String> arguments, int timeout) {
  return arguments.map((argument) {
    if (argument.startsWith('--timeout=')) {
      return "--timeout=$timeout";
    } else {
      return argument;
    }
  }).toList();
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
  Command command;
  int timeout;
  bool timedOut = false;
  DateTime startTime;
  Timer timeoutTimer;
  List<int> stdout = <int>[];
  List<int> stderr = <int>[];
  bool compilationSkipped = false;
  Completer<CommandOutput> completer;

  RunningProcess(Command this.command, this.timeout);

  Future<CommandOutput> run() {
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
        var processEnvironment = _createProcessEnvironment();
        var commandArguments = _modifySeleniumTimeout(command.arguments,
                                                      timeout);
        Future processFuture =
            io.Process.start(command.executable,
                             commandArguments,
                             environment: processEnvironment);
        processFuture.then((io.Process process) {
          // Close stdin so that tests that try to block on input will fail.
          process.stdin.close();
          void timeoutHandler() {
            timedOut = true;
            if (process != null) {
              process.kill();
            }
          }
          Future.wait([process.exitCode,
                       _drainStream(process.stdout, stdout),
                       _drainStream(process.stderr, stderr)])
              .then((values) => _commandComplete(values[0]));
          timeoutTimer = new Timer(new Duration(seconds: timeout),
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
    var commandOutput = createCommandOutput(
        command,
        exitCode,
        timedOut,
        stdout,
        stderr,
        new DateTime.now().difference(startTime),
        compilationSkipped);
    return commandOutput;
  }

  Future _drainStream(Stream<List<int>> source, List<int> destination) {
    return source.listen(destination.addAll).asFuture();
  }

  Map<String, String> _createProcessEnvironment() {
    var environment = io.Platform.environment;

    if (command.environmentOverrides != null) {
      for (var key in command.environmentOverrides.keys) {
        environment[key] = command.environmentOverrides[key];
      }
    }
    for (var excludedEnvironmentVariable in EXCLUDED_ENVIRONMENT_VARIABLES) {
      environment.remove(excludedEnvironmentVariable);
    }

    return environment;
  }
}

class BatchRunnerProcess {
  static bool isWindows = io.Platform.operatingSystem == 'windows';

  final batchRunnerTypes = {
      'selenium' : {
          'run_executable' : 'python',
          'run_arguments' : ['tools/testing/run_selenium.py', '--batch'],
          'terminate_command' : ['--terminate'],
      },
      'dartanalyzer' : {
        'run_executable' :
           isWindows ?
             'sdk\\bin\\dartanalyzer_developer.bat'
              : 'sdk/bin/dartanalyzer_developer',
        'run_arguments' : ['--batch'],
        'terminate_command' : null,
      },
      'dart2analyzer' : {
        // This is a unix shell script, no windows equivalent available
        'run_executable' : 'editor/tools/analyzer_experimental',
        'run_arguments' : ['--batch'],
        'terminate_command' : null,
    },
  };

  Completer<CommandOutput> _completer;
  Command _command;
  List<String> _arguments;
  String _runnerType;

  io.Process _process;
  Map _processEnvironmentOverrides;
  Completer _stdoutCompleter;
  Completer _stderrCompleter;
  StreamSubscription<String> _stdoutSubscription;
  StreamSubscription<String> _stderrSubscription;
  Function _processExitHandler;

  bool _currentlyRunning = false;
  List<int> _testStdout;
  List<int> _testStderr;
  String _status;
  DateTime _startTime;
  Timer _timer;

  BatchRunnerProcess();

  Future<CommandOutput> runCommand(String runnerType, Command command,
                                   int timeout, List<String> arguments) {
    assert(_completer == null);
    assert(!_currentlyRunning);

    _completer = new Completer<CommandOutput>();
    bool sameRunnerType = _runnerType == runnerType &&
        _dictEquals(_processEnvironmentOverrides, command.environmentOverrides);
    _runnerType = runnerType;
    _currentlyRunning = true;
    _command = command;
    _arguments = arguments;

    _processEnvironmentOverrides = command.environmentOverrides;

    if (_process == null) {
      // Start process if not yet started.
      _startProcess(() {
        doStartTest(command, timeout);
      });
    } else if (!sameRunnerType) {
      // Restart this runner with the right executable for this test if needed.
      _processExitHandler = (_) {
        _startProcess(() {
          doStartTest(command, timeout);
        });
      };
      _process.kill();
    } else {
      doStartTest(command, timeout);
    }
    return _completer.future;
  }

  Future terminate() {
    if (_process == null) return new Future.value(true);
    Completer terminateCompleter = new Completer();
    Timer killTimer;
    _processExitHandler = (_) {
      if (killTimer != null) killTimer.cancel();
      terminateCompleter.complete(true);
    };
    var shutdownCommand = batchRunnerTypes[_runnerType]['terminate_command'];
    if (shutdownCommand != null && !shutdownCommand.isEmpty) {
      // Use a graceful shutdown so our Selenium script can close
      // the open browser processes. On Windows, signals do not exist
      // and a kill is a hard kill.
      _process.stdin.writeln(shutdownCommand.join(' '));

      // In case the run_selenium process didn't close, kill it after 30s
      killTimer = new Timer(new Duration(seconds: 30), _process.kill);
    } else {
      _process.kill();
    }

    return terminateCompleter.future;
  }

  void doStartTest(Command command, int timeout) {
    _startTime = new DateTime.now();
    _testStdout = [];
    _testStderr = [];
    _status = null;
    _stdoutCompleter = new Completer();
    _stderrCompleter = new Completer();
    _timer = new Timer(new Duration(seconds: timeout),
                       _timeoutHandler);

    var line = _createArgumentsLine(_arguments, timeout);
    _process.stdin.write(line);
    _stdoutSubscription.resume();
    _stderrSubscription.resume();
    Future.wait([_stdoutCompleter.future,
                 _stderrCompleter.future]).then((_) => _reportResult());
  }

  String _createArgumentsLine(List<String> arguments, int timeout) {
    arguments = _modifySeleniumTimeout(arguments, timeout);
    return arguments.join(' ') + '\n';
  }

  void _reportResult() {
    if (!_currentlyRunning) return;
    // _status == '>>> TEST {PASS, FAIL, OK, CRASH, FAIL, TIMEOUT}'

    var outcome = _status.split(" ")[2];
    var exitCode = 0;
    if (outcome == "CRASH") exitCode = CRASHING_BROWSER_EXITCODE;
    if (outcome == "FAIL" || outcome == "TIMEOUT") exitCode = 1;
    var output = createCommandOutput(_command,
                        exitCode,
                        (outcome == "TIMEOUT"),
                        _testStdout,
                        _testStderr,
                        new DateTime.now().difference(_startTime),
                        false);
    assert(_completer != null);
    _completer.complete(output);
    _completer = null;
    _currentlyRunning = false;
  }

  ExitCodeEvent makeExitHandler(String status) {
    void handler(int exitCode) {
      if (_currentlyRunning) {
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
    var executable = batchRunnerTypes[_runnerType]['run_executable'];
    var arguments = batchRunnerTypes[_runnerType]['run_arguments'];
    var environment = new Map.from(io.Platform.environment);
    if (_processEnvironmentOverrides != null) {
      for (var key in _processEnvironmentOverrides.keys) {
        environment[key] = _processEnvironmentOverrides[key];
      }
    }
    Future processFuture = io.Process.start(executable,
                                            arguments,
                                            environment: environment);
    processFuture.then((io.Process p) {
      _process = p;

      var _stdoutStream =
          _process.stdout
              .transform(UTF8.decoder)
              .transform(new LineSplitter());
      _stdoutSubscription = _stdoutStream.listen((String line) {
        if (line.startsWith('>>> TEST')) {
          _status = line;
        } else if (line.startsWith('>>> BATCH')) {
          // ignore
        } else if (line.startsWith('>>> ')) {
          throw new Exception("Unexpected command from batch runner: '$line'.");
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
              .transform(UTF8.decoder)
              .transform(new LineSplitter());
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
      print("  Command: $executable ${arguments.join(' ')} ($_arguments)");
      print("  Error: $e");
      // If there is an error starting a batch process, chances are that
      // it will always fail. So rather than re-trying a 1000+ times, we
      // exit.
      io.exit(1);
      return true;
    });
  }

  bool _dictEquals(Map a, Map b) {
    if (a == null) return b == null;
    if (b == null) return false;
    for (var key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}


/**
 * [TestCaseEnqueuer] takes a list of TestSuites, generates TestCases and
 * builds a dependency graph of all commands in every TestSuite.
 *
 * It will maintain three helper data structures
 *  - command2node: A mapping from a [Command] to a node in the dependency graph
 *  - command2testCases: A mapping from [Command] to all TestCases that it is
 *    part of.
 *  - remainingTestCases: A set of TestCases that were enqueued but are not
 *    finished
 *
 * [Command] and it's subclasses all have hashCode/operator== methods defined
 * on them, so we can safely use them as keys in Map/Set objects.
 */
class TestCaseEnqueuer {
  final dgraph.Graph graph;
  final Function _onTestCaseAdded;

  final command2node = new Map<Command, dgraph.Node>();
  final command2testCases = new Map<Command, List<TestCase>>();
  final remainingTestCases = new Set<TestCase>();

  TestCaseEnqueuer(this.graph, this._onTestCaseAdded);

  void enqueueTestSuites(List<TestSuite> testSuites) {
    void newTest(TestCase testCase) {
      remainingTestCases.add(testCase);

      var lastNode;
      for (var command in testCase.commands) {
        // Make exactly *one* node in the dependency graph for every command.
        // This ensures that we never have two commands c1 and c2 in the graph
        // with "c1 == c2".
        var node = command2node[command];
        if (node == null) {
          var requiredNodes = (lastNode != null) ? [lastNode] : [];
          node = graph.newNode(command, requiredNodes);
          command2node[command] = node;
          command2testCases[command] = <TestCase>[];
        }
        // Keep mapping from command to all testCases that refer to it
        command2testCases[command].add(testCase);

        lastNode = node;
      }
      _onTestCaseAdded(testCase);
    }

    // Cache information about test cases per test suite. For multiple
    // configurations there is no need to repeatedly search the file
    // system, generate tests, and search test files for options.
    var testCache = new Map<String, List<TestInformation>>();

    Iterator<TestSuite> iterator = testSuites.iterator;
    void enqueueNextSuite() {
      if (!iterator.moveNext()) {
        // We're finished with building the dependency graph.
        graph.sealGraph();
      } else {
        iterator.current.forEachTest(newTest, testCache, enqueueNextSuite);
      }
    }
    enqueueNextSuite();
  }
}


/*
 * [CommandEnqueuer] will
 *  - change node.state to NodeState.Enqueuing as soon as all dependencies have
 *    a state of NodeState.Successful
 *  - change node.state to NodeState.UnableToRun if one or more dependencies
 *    have a state of NodeState.Failed/NodeState.UnableToRun.
 */
class CommandEnqueuer {
  static final INIT_STATES = [dgraph.NodeState.Initialized,
                              dgraph.NodeState.Waiting];
  static final FINISHED_STATES = [dgraph.NodeState.Successful,
                                  dgraph.NodeState.Failed,
                                  dgraph.NodeState.UnableToRun];
  final dgraph.Graph _graph;

  CommandEnqueuer(this._graph) {
    var eventCondition = _graph.events.where;

    eventCondition((e) => e is dgraph.NodeAddedEvent).listen((event) {
      dgraph.Node node = event.node;
      _changeNodeStateIfNecessary(node);
    });

    eventCondition((e) => e is dgraph.StateChangedEvent).listen((event) {
      if (event.from == dgraph.NodeState.Processing) {
        assert(FINISHED_STATES.contains(event.to));
        for (var dependendNode in event.node.neededFor) {
          _changeNodeStateIfNecessary(dependendNode);
        }
      }
    });
  }

  // Called when either a new node was added or if one of it's dependencies
  // changed it's state.
  void _changeNodeStateIfNecessary(dgraph.Node node) {
    assert(INIT_STATES.contains(node.state));
    bool allDependenciesFinished =
        node.dependencies.every((node) => FINISHED_STATES.contains(node.state));

    var newState = dgraph.NodeState.Waiting;
    if (allDependenciesFinished) {
      bool allDependenciesSuccessful = node.dependencies.every(
          (dep) => dep.state == dgraph.NodeState.Successful);

      if (allDependenciesSuccessful) {
        newState = dgraph.NodeState.Enqueuing;
      } else {
        newState = dgraph.NodeState.UnableToRun;
      }
    }
    if (node.state != newState) {
      _graph.changeState(node, newState);
    }
  }
}

/*
 * [CommandQueue] will listen for nodes entering the NodeState.ENQUEUING state,
 * queue them up and run them. While nodes are processed they will be in the
 * NodeState.PROCESSING state. After running a command, the node will change
 * to a state of NodeState.Successfull or NodeState.Failed.
 *
 * It provides a synchronous stream [completedCommands] which provides the
 * [CommandOutputs] for the finished commands.
 *
 * It provides a [done] future, which will complete once there are no more
 * nodes left in the states Initialized/Waiting/Enqueing/Processing
 * and the [executor] has cleaned up it's resources.
 */
class CommandQueue {
  final dgraph.Graph graph;
  final CommandExecutor executor;
  final TestCaseEnqueuer enqueuer;

  final Queue<Command> _runQueue = new Queue<Command>();
  final _commandOutputStream =  new StreamController<CommandOutput>(sync: true);
  final _completer =  new Completer();

  int _numProcesses = 0;
  int _maxProcesses;
  int _numBrowserProcesses = 0;
  int _maxBrowserProcesses;
  bool _finishing = false;
  bool _verbose = false;

  CommandQueue(this.graph, this.enqueuer, this.executor,
               this._maxProcesses, this._maxBrowserProcesses, this._verbose) {
    var eventCondition = graph.events.where;
    eventCondition((event) => event is dgraph.StateChangedEvent)
        .listen((event) {
          if (event.to == dgraph.NodeState.Enqueuing) {
            assert(event.from == dgraph.NodeState.Initialized ||
                   event.from == dgraph.NodeState.Waiting);
            graph.changeState(event.node, dgraph.NodeState.Processing);
            var command = event.node.userData;
            if (event.node.dependencies.length > 0) {
              _runQueue.addFirst(command);
            } else {
              _runQueue.add(command);
            }
            Timer.run(() => _tryRunNextCommand());
          }
    });
    // We're finished if the graph is sealed and all nodes are in a finished
    // state (Successfull, Failed or UnableToRun).
    // So we're calling '_checkDone()' to check whether that condition is met
    // and we can cleanup.
    graph.events.listen((dgraph.GraphEvent event) {
      if (event is dgraph.GraphSealedEvent) {
        _checkDone();
      } else if (event is dgraph.StateChangedEvent) {
        if (event.to == dgraph.NodeState.UnableToRun) {
          _checkDone();
        }
      }
    });
  }

  Stream<CommandOutput> get completedCommands => _commandOutputStream.stream;

  Future get done => _completer.future;

  void _tryRunNextCommand() {
    _checkDone();

    if (_numProcesses < _maxProcesses && !_runQueue.isEmpty) {
      Command command = _runQueue.removeFirst();
      var isBrowserCommand =
          command is SeleniumTestCommand ||
          command is BrowserTestCommand;

      if (isBrowserCommand && _numBrowserProcesses == _maxBrowserProcesses) {
        // If there is no free browser runner, put it back into the queue.
        _runQueue.add(command);
        // Don't lose a process.
        new Timer(new Duration(milliseconds: 100), _tryRunNextCommand);
        return;
      }

      _numProcesses++;
      if (isBrowserCommand) _numBrowserProcesses++;

      var node = enqueuer.command2node[command];
      Iterable<TestCase> testCases = enqueuer.command2testCases[command];
      // If a command is part of many TestCases we set the timeout to be
      // the maximum over all [TestCase.timeout]s. At some point, we might
      // eliminate [TestCase.timeout] completely and move it to [Command].
      int timeout = testCases.map((TestCase test) => test.timeout)
          .fold(0, math.max);

      if (_verbose) {
        print('Running "${command.displayName}" command: $command');
      }

      executor.runCommand(node, command, timeout).then((CommandOutput output) {
        assert(command == output.command);

        _commandOutputStream.add(output);
        if (output.canRunDependendCommands) {
          graph.changeState(node, dgraph.NodeState.Successful);
        } else {
          graph.changeState(node, dgraph.NodeState.Failed);
        }

        _numProcesses--;
        if (isBrowserCommand) _numBrowserProcesses--;

        // Don't loose a process
        Timer.run(() => _tryRunNextCommand());
      });
    }
  }

  void _checkDone() {
    if (!_finishing &&
        _runQueue.isEmpty &&
        _numProcesses == 0 &&
        graph.isSealed &&
        graph.stateCount(dgraph.NodeState.Initialized) == 0 &&
        graph.stateCount(dgraph.NodeState.Waiting) == 0 &&
        graph.stateCount(dgraph.NodeState.Enqueuing) == 0 &&
        graph.stateCount(dgraph.NodeState.Processing) == 0) {
      _finishing = true;
      executor.cleanup().then((_) {
        _completer.complete();
        _commandOutputStream.close();
      });
    }
  }
}


/*
 * [CommandExecutor] is responsible for executing commands. It will make sure
 * that the the following two constraints are satisfied
 *  - [:numberOfProcessesUsed <= maxProcesses:]
 *  - [:numberOfBrowserProcessesUsed <= maxBrowserProcesses:]
 *
 * It provides a [runCommand] method which will complete with a
 * [CommandOutput] object.
 *
 * It provides a [cleanup] method to free all the allocated resources.
 */
abstract class CommandExecutor {
  Future cleanup();
  // TODO(kustermann): The [timeout] parameter should be a property of Command
  Future<CommandOutput> runCommand(
      dgraph.Node node, Command command, int timeout);
}

class CommandExecutorImpl implements CommandExecutor {
  final Map globalConfiguration;
  final int maxProcesses;
  final int maxBrowserProcesses;

  // For dartc/selenium batch processing we keep a list of batch processes.
  final _batchProcesses = new Map<String, List<BatchRunnerProcess>>();
  // For browser tests we keepa [BrowserTestRunner]
  final _browserTestRunners = new Map<String, BrowserTestRunner>();

  bool _finishing = false;

  CommandExecutorImpl(
      this.globalConfiguration, this.maxProcesses, this.maxBrowserProcesses);

  Future cleanup() {
    assert(!_finishing);
    _finishing = true;

    Future _terminateBatchRunners() {
      var futures = [];
      for (var runners in _batchProcesses.values) {
        futures.addAll(runners.map((runner) => runner.terminate()));
      }
      return Future.wait(futures);
    }

    Future _terminateBrowserRunners() {
      var futures =
          _browserTestRunners.values.map((runner) => runner.terminate());
      return Future.wait(futures);
    }

    return Future.wait([_terminateBatchRunners(), _terminateBrowserRunners()]);
  }

  Future<CommandOutput> runCommand(node, Command command, int timeout) {
    assert(!_finishing);

    Future<CommandOutput> runCommand(int retriesLeft) {
      return _runCommand(command, timeout).then((CommandOutput output) {
        if (retriesLeft > 0 && shouldRetryCommand(output)) {
          DebugLogger.warning("Rerunning Command: ($retriesLeft "
                              "attempt(s) remains) [cmd: $command]");
          return runCommand(retriesLeft - 1);
        } else {
          return new Future.value(output);
        }
      });
    }
    return runCommand(command.maxNumRetries);
  }

  Future<CommandOutput> _runCommand(Command command, int timeout) {
    var batchMode = !globalConfiguration['noBatch'];

    if (command is BrowserTestCommand) {
      return _startBrowserControllerTest(command, timeout);
    } else if (command is SeleniumTestCommand && batchMode) {
      var arguments = ['--force-refresh', '--browser=${command.browser}',
                       '--timeout=${timeout}', '--out', '${command.url}'];
      return _getBatchRunner(command.browser)
          .runCommand('selenium', command, timeout, arguments);
    } else if (command is AnalysisCommand && batchMode) {
      return _getBatchRunner(command.flavor)
          .runCommand(command.flavor, command, timeout, command.arguments);
    } else {
      return new RunningProcess(command, timeout).run();
    }
  }

  BatchRunnerProcess _getBatchRunner(String identifier) {
    // Start batch processes if needed
    var runners = _batchProcesses[identifier];
    if (runners == null) {
      runners = new List<BatchRunnerProcess>(maxProcesses);
      for (int i = 0; i < maxProcesses; i++) {
        runners[i] = new BatchRunnerProcess();
      }
      _batchProcesses[identifier] = runners;
    }

    for (var runner in runners) {
      if (!runner._currentlyRunning) return runner;
    }
    throw new Exception('Unable to find inactive batch runner.');
  }

  Future<CommandOutput> _startBrowserControllerTest(
      BrowserTestCommand browserCommand, int timeout) {
    var completer = new Completer<CommandOutput>();

    var callback = (output, delayUntilTestStarted, duration) {
      bool timedOut = output == "TIMEOUT";
      String stderr = "";
      if (timedOut) {
        if (delayUntilTestStarted != null) {
          stderr = "This test timed out. The delay until the test was actually "
                   "started was: $delayUntilTestStarted.";
        } else {
          stderr = "This test has not notified test.py that it started running."
                   " This could be a bug in test.py! "
                   "Please contact ricow/kustermann";
        }
      }
      var commandOutput = createCommandOutput(browserCommand,
                          0,
                          timedOut,
                          encodeUtf8(output),
                          encodeUtf8(stderr),
                          duration,
                          false);
      completer.complete(commandOutput);
    };
    BrowserTest browserTest = new BrowserTest(browserCommand.url,
                                              callback,
                                              timeout);
    _getBrowserTestRunner(browserCommand.browser).then((testRunner) {
      testRunner.queueTest(browserTest);
    });

    return completer.future;
  }

  Future<BrowserTestRunner> _getBrowserTestRunner(String browser) {
    var local_ip = globalConfiguration['local_ip'];
    var num_browsers = maxBrowserProcesses;
    if (_browserTestRunners[browser] == null) {
      var testRunner =
        new BrowserTestRunner(local_ip, browser, num_browsers);
      if (globalConfiguration['verbose']) {
        testRunner.logger = DebugLogger.info;
      }
      _browserTestRunners[browser] = testRunner;
      return testRunner.start().then((started) {
        if (started) {
          return testRunner;
        }
        print("Issue starting browser test runner");
        io.exit(1);
      });
    }
    return new Future.value(_browserTestRunners[browser]);
  }
}

class RecordingCommandExecutor implements CommandExecutor {
  TestCaseRecorder _recorder;

  RecordingCommandExecutor(Path path)
      : _recorder = new TestCaseRecorder(path);

  Future<CommandOutput> runCommand(node, Command command, int timeout) {
    assert(node.dependencies.length == 0);
    assert(_cleanEnvironmentOverrides(command.environmentOverrides));
    _recorder.nextCommand(command, timeout);
    // Return dummy CommandOutput
    var output =
        createCommandOutput(command, 0, false, [], [], const Duration(), false);
    return new Future.value(output);
  }

  Future cleanup() {
    _recorder.finish();
    return new Future.value();
  }

  // Returns [:true:] if the environment contains only 'DART_CONFIGURATION'
  bool _cleanEnvironmentOverrides(Map environment) {
    if (environment == null) return true;
    return environment.length == 0 ||
        (environment.length == 1 &&
         environment.containsKey("DART_CONFIGURATION"));

  }
}

class ReplayingCommandExecutor implements CommandExecutor {
  TestCaseOutputArchive _archive = new TestCaseOutputArchive();

  ReplayingCommandExecutor(Path path) {
    _archive.loadFromPath(path);
  }

  Future cleanup() => new Future.value();

  Future<CommandOutput> runCommand(node, Command command, int timeout) {
    assert(node.dependencies.length == 0);
    return new Future.value(_archive.outputOf(command));
  }
}

bool shouldRetryCommand(CommandOutput output) {
  var command = output.command;

  if (!output.successful) {
    List<String> stdout, stderr;

    decodeOutput() {
      if (stdout == null && stderr == null) {
        stdout = decodeUtf8(output.stderr).split("\n");
        stderr = decodeUtf8(output.stderr).split("\n");
      }
    }

    if (io.Platform.operatingSystem == 'linux') {
      decodeOutput();
      // No matter which command we ran: If we get failures due to the
      // "xvfb-run" issue 7564, try re-running the test.
      bool containsFailureMsg(String line) {
        return line.contains(MESSAGE_CANNOT_OPEN_DISPLAY) ||
               line.contains(MESSAGE_FAILED_TO_RUN_COMMAND);
      }
      if (stdout.any(containsFailureMsg) || stderr.any(containsFailureMsg)) {
        return true;
      }
    }

    if (command is BrowserTestCommand) {
      // We do not re-run tests on the new browser controller, since it should
      // not be as flaky as selenium.
      return false;
    } else if (command is SeleniumTestCommand) {
      // Selenium tests can be flaky. Try re-running.
      return true;
    } else if (command is ContentShellCommand) {
      // FIXME(kustermann): Remove this condition once we figured out why
      // content_shell is sometimes not able to fetch resources from the
      // HttpServer on windows.
      // TODO(kustermann): Don't blindly re-run DRT tests on windows but rather
      // check if the stderr/stdout indicates that we actually have this issue.
      return io.Platform.operatingSystem == 'windows';
    }
  }
  return false;
}

/*
 * [TestCaseCompleter] will listen for
 * NodeState.Processing -> NodeState.{Successfull,Failed} state changes and
 * will complete a TestCase if it is finished.
 *
 * It provides a stream [finishedTestCases], which will stream all TestCases
 * once they're finished. After all TestCases are done, the stream will be
 * closed.
 */
class TestCaseCompleter {
  static final COMPLETED_STATES = [dgraph.NodeState.Failed,
                                   dgraph.NodeState.Successful];
  final dgraph.Graph graph;
  final TestCaseEnqueuer enqueuer;
  final CommandQueue commandQueue;

  Map<Command, CommandOutput> _outputs = new Map<Command, CommandOutput>();
  bool _closed = false;
  StreamController<TestCase> _controller = new StreamController<TestCase>();

  TestCaseCompleter(this.graph, this.enqueuer, this.commandQueue) {
    var eventCondition = graph.events.where;

    // Store all the command outputs -- they will be delivered synchronously
    // (i.e. before state changes in the graph)
    commandQueue.completedCommands.listen((CommandOutput output) {
      _outputs[output.command] = output;
    });

    // Listen for NodeState.Processing -> NodeState.{Successfull,Failed}
    // changes.
    eventCondition((event) => event is dgraph.StateChangedEvent)
        .listen((dgraph.StateChangedEvent event) {
          if (event.from == dgraph.NodeState.Processing) {
            assert(COMPLETED_STATES.contains(event.to));
            _completeTestCasesIfPossible(event.node.userData);

            if (!_closed &&
                graph.isSealed &&
                enqueuer.remainingTestCases.isEmpty) {
              _controller.close();
              _closed = true;
            }
          }
    });

    // Listen also for GraphSealedEvent's. If there is not a single node in the
    // graph, we still want to finish after the graph was sealed.
    eventCondition((event) => event is dgraph.GraphSealedEvent)
        .listen((dgraph.GraphSealedEvent event) {
          if (!_closed && enqueuer.remainingTestCases.isEmpty) {
            _controller.close();
            _closed = true;
          }
    });
  }

  Stream<TestCase> get finishedTestCases => _controller.stream;

  void _completeTestCasesIfPossible(Command command) {
    assert(_outputs[command] != null);

    var testCases = enqueuer.command2testCases[command];

    // Update TestCases with command outputs
    for (TestCase test in testCases) {
      for (var icommand in test.commands) {
        var output = _outputs[icommand];
        if (output != null) {
          test.commandOutputs[icommand] = output;
        }
      }
    }

    void completeTestCase(TestCase testCase) {
      if (enqueuer.remainingTestCases.contains(testCase)) {
        _controller.add(testCase);
        enqueuer.remainingTestCases.remove(testCase);
      } else {
        DebugLogger.error("${testCase.displayName} would be finished twice");
      }
    }

    for (var testCase in testCases) {
      // Ask the [testCase] if it's done. Note that we assume, that
      // [TestCase.isFinished] will return true if all commands were executed
      // or if a previous one failed.
      if (testCase.isFinished) {
        completeTestCase(testCase);
      }
    }
  }
}


class ProcessQueue {
  Map _globalConfiguration;

  bool _allTestsWereEnqueued = false;

  bool _listTests;
  Function _allDone;
  final dgraph.Graph _graph = new dgraph.Graph();
  List<EventListener> _eventListener;

  ProcessQueue(this._globalConfiguration,
               maxProcesses,
               maxBrowserProcesses,
               DateTime startTime,
               testSuites,
               this._eventListener,
               this._allDone,
               [bool verbose = false,
                this._listTests = false,
                String recordingOutputFile,
                String recordedInputFile]) {
    bool recording = recordingOutputFile != null;
    bool replaying = recordedInputFile != null;

    // When the graph building is finished, notify event listeners.
    _graph.events
      .where((event) => event is dgraph.GraphSealedEvent).listen((event) {
        eventAllTestsKnown();
    });

    // Build up the dependency graph
    var testCaseEnqueuer = new TestCaseEnqueuer(_graph, (TestCase newTestCase) {
      eventTestAdded(newTestCase);
    });

    // Queue commands as they become "runnable"
    var commandEnqueuer = new CommandEnqueuer(_graph);

    // CommandExecutor will execute commands
    var executor;
    if (recording) {
      executor = new RecordingCommandExecutor(new Path(recordingOutputFile));
    } else if (replaying) {
      executor = new ReplayingCommandExecutor(new Path(recordedInputFile));
    } else {
      executor = new CommandExecutorImpl(
          _globalConfiguration, maxProcesses, maxBrowserProcesses);
    }

    // Run "runnable commands" using [executor] subject to
    // maxProcesses/maxBrowserProcesses constraint
    var commandQueue = new CommandQueue(
        _graph, testCaseEnqueuer, executor, maxProcesses, maxBrowserProcesses,
        verbose);

    // Finish test cases when all commands were run (or some failed)
    var testCaseCompleter =
        new TestCaseCompleter(_graph, testCaseEnqueuer, commandQueue);
    testCaseCompleter.finishedTestCases.listen(
      (TestCase finishedTestCase) {
        // If we're recording, we don't report any TestCases to listeners.
        if (!recording) {
          eventFinishedTestCase(finishedTestCase);
        }
      },
      onDone: () {
        // Wait until the commandQueue/execturo is done (it may need to stop
        // batch runners, browser controllers, ....)
        commandQueue.done.then((_) => eventAllTestsDone());
      });

    // Start enqueing all TestCases
    testCaseEnqueuer.enqueueTestSuites(testSuites);
  }

  void eventFinishedTestCase(TestCase testCase) {
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
    _allDone();
  }
}
