// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;

import 'browser_controller.dart';
import 'command.dart';
import 'configuration.dart';
import 'expectation.dart';
import 'test_runner.dart';
import 'utils.dart';

/// CommandOutput records the output of a completed command: the process's exit
/// code, the standard output and standard error, whether the process timed out,
/// and the time the process took to run. It does not contain a pointer to the
/// [TestCase] this is the output of, so some functions require the test case
/// to be passed as an argument.
class CommandOutput extends UniqueObject {
  final Command command;

  final bool hasTimedOut;

  final Duration time;

  final int exitCode;

  final int pid;

  final List<int> stdout;
  final List<int> stderr;

  final bool compilationSkipped;

  final List<String> diagnostics = [];

  CommandOutput(this.command, this.exitCode, this.hasTimedOut, this.stdout,
      this.stderr, this.time, this.compilationSkipped, this.pid);

  Expectation result(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasFailed(testCase)) return Expectation.fail;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    return Expectation.pass;
  }

  bool get hasCrashed {
    // dart2js exits with code 253 in case of unhandled exceptions.
    // The dart binary exits with code 253 in case of an API error such
    // as an invalid snapshot file.
    // In either case an exit code of 253 is considered a crash.
    if (exitCode == 253) return true;
    if (io.Platform.operatingSystem == 'windows') {
      // The VM uses std::abort to terminate on asserts.
      // std::abort terminates with exit code 3 on Windows.
      if (exitCode == 3 || exitCode == browserCrashExitCode) {
        return !hasTimedOut;
      }
      // If a program receives an uncaught system exception, the program
      // terminates with the exception code as exit code.
      // The 0x3FFFFF00 mask here tries to determine if an exception indicates
      // a crash of the program.
      // System exception codes can be found in 'winnt.h', for example
      // "#define STATUS_ACCESS_VIOLATION  ((DWORD) 0xC0000005)"
      return (!hasTimedOut && (exitCode < 0) && ((0x3FFFFF00 & exitCode) == 0));
    }
    return !hasTimedOut && ((exitCode < 0));
  }

  bool _didFail(TestCase testCase) => exitCode != 0 && !hasCrashed;

  bool get canRunDependendCommands {
    // FIXME(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  bool get successful {
    // FIXME(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  // TODO(bob): Remove.
  // Reverse result of a negative test.
  bool hasFailed(TestCase testCase) {
    return testCase.isNegative ? !_didFail(testCase) : _didFail(testCase);
  }

  bool get hasNonUtf8 => exitCode == nonUtfFakeExitCode;

  Expectation _negateOutcomeIfNegativeTest(
      Expectation outcome, bool isNegative) {
    if (!isNegative) return outcome;
    if (outcome == Expectation.ignore) return outcome;
    if (outcome.canBeOutcomeOf(Expectation.fail)) {
      return Expectation.pass;
    }
    return Expectation.fail;
  }
}

class ContentShellCommandOutput extends CommandOutput {
  // Although tests are reported as passing, content shell sometimes exits with
  // a nonzero exitcode which makes our dartium builders extremely falky.
  // See: http://dartbug.com/15139.
  // TODO(rnystrom): Is this still needed? The underlying bug is closed.
  static const _whitelistedContentShellExitCode = -1073740022;

  static bool _failedBecauseOfFlakyInfrastructure(
      Command command, bool timedOut, List<int> stderrBytes) {
    // If the browser test failed, it may have been because content shell
    // and the virtual framebuffer X server didn't hook up, or it crashed with
    // a core dump. Sometimes content shell crashes after it has set the stdout
    // to PASS, so we have to do this check first.
    // Content shell also fails with a broken pipe message: Issue 26739
    var zygoteCrash =
        new RegExp(r"ERROR:zygote_linux\.cc\(\d+\)] write: Broken pipe");
    var stderr = decodeUtf8(stderrBytes);
    // TODO(7564): See http://dartbug.com/7564
    // This may not be happening anymore.  Test by removing this suppression.
    if (stderr.contains(cannotOpenDisplayMessage) ||
        stderr.contains(failedToRunCommandMessage)) {
      DebugLogger.warning(
          "Warning: Failure because of missing XDisplay. Test ignored");
      return true;
    }
    // TODO(26739): See http://dartbug.com/26739
    if (zygoteCrash.hasMatch(stderr)) {
      DebugLogger.warning("Warning: Failure because of content_shell "
          "zygote crash. Test ignored");
      return true;
    }
    return false;
  }

  final bool _infraFailure;

  ContentShellCommandOutput(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : _infraFailure =
            _failedBecauseOfFlakyInfrastructure(command, timedOut, stderr),
        super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, 0);

  Expectation result(TestCase testCase) {
    if (_infraFailure) {
      return Expectation.ignore;
    }

    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    var outcome = _getOutcome();

    if (testCase.hasRuntimeError) {
      if (!outcome.canBeOutcomeOf(Expectation.runtimeError)) {
        return Expectation.missingRuntimeError;
      }
    }
    if (testCase.isNegative) {
      if (outcome.canBeOutcomeOf(Expectation.fail)) return Expectation.pass;
      return Expectation.fail;
    }
    return outcome;
  }

  bool get successful => canRunDependendCommands;

  bool get canRunDependendCommands {
    // We cannot rely on the exit code of content_shell as a method to
    // determine if we were successful or not.
    return super.canRunDependendCommands && !_didFail(null);
  }

  bool get hasCrashed => super.hasCrashed || _rendererCrashed;

  Expectation _getOutcome() {
    if (_browserTestFailure) {
      return Expectation.runtimeError;
    }
    return Expectation.pass;
  }

  bool get _rendererCrashed =>
      decodeUtf8(super.stdout).contains("#CRASHED - rendere");

  bool get _browserTestFailure {
    // Browser tests fail unless stdout contains
    // 'Content-Type: text/plain' followed by 'PASS'.
    var hasContentType = false;
    var stdoutLines = decodeUtf8(super.stdout).split("\n");
    var containsFail = false;
    var containsPass = false;
    for (String line in stdoutLines) {
      switch (line) {
        case 'Content-Type: text/plain':
          hasContentType = true;
          break;
        case 'FAIL':
          if (hasContentType) {
            containsFail = true;
          }
          break;
        case 'PASS':
          if (hasContentType) {
            containsPass = true;
          }
          break;
      }
    }
    if (hasContentType) {
      if (containsFail && containsPass) {
        DebugLogger.warning("Test had 'FAIL' and 'PASS' in stdout. ($command)");
      }
      if (!containsFail && !containsPass) {
        DebugLogger.warning("Test had neither 'FAIL' nor 'PASS' in stdout. "
            "($command)");
        return true;
      }
      if (containsFail) {
        return true;
      }
      assert(containsPass);
      if (exitCode != 0) {
        var message = "All tests passed, but exitCode != 0. "
            "Actual exitcode: $exitCode. "
            "($command)";
        DebugLogger.warning(message);
        diagnostics.add(message);
      }

      var isWindows = io.Platform.operatingSystem == 'windows';
      return (!hasCrashed &&
          exitCode != 0 &&
          (!isWindows || exitCode != _whitelistedContentShellExitCode));
    }

    DebugLogger.warning("Couldn't find 'Content-Type: text/plain' in output. "
        "($command).");
    return true;
  }
}

class HtmlBrowserCommandOutput extends ContentShellCommandOutput {
  HtmlBrowserCommandOutput(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped);

  bool _didFail(TestCase testCase) {
    return _getOutcome() != Expectation.pass;
  }

  bool get _browserTestFailure {
    // We should not need to convert back and forward.
    var output = decodeUtf8(super.stdout);
    if (output.contains("FAIL")) return true;
    return !output.contains("PASS");
  }
}

class BrowserTestJsonResult {
  static const _allowedTypes = const [
    'sync_exception',
    'window_onerror',
    'script_onerror',
    'window_compilationerror',
    'print',
    'message_received',
    'dom',
    'debug'
  ];

  final Expectation outcome;
  final String htmlDom;
  final List<dynamic> events;

  BrowserTestJsonResult(this.outcome, this.htmlDom, this.events);

  static BrowserTestJsonResult parseFromString(String content) {
    void validate(String assertion, bool value) {
      if (!value) {
        throw "InvalidFormat sent from browser driving page: $assertion:\n\n"
            "$content";
      }
    }

    try {
      var events = JSON.decode(content);
      if (events != null) {
        validate("Message must be a List", events is List);

        var messagesByType = <String, List<String>>{};
        _allowedTypes.forEach((type) => messagesByType[type] = <String>[]);

        for (var entry in events) {
          validate("An entry must be a Map", entry is Map);

          var type = entry['type'];
          var value = entry['value'] as String;
          var timestamp = entry['timestamp'];

          validate("'type' of an entry must be a String", type is String);
          validate("'type' has to be in $_allowedTypes.",
              _allowedTypes.contains(type));
          validate(
              "'timestamp' of an entry must be a number", timestamp is num);

          messagesByType[type].add(value);
        }
        validate("The message must have exactly one 'dom' entry.",
            messagesByType['dom'].length == 1);

        var dom = messagesByType['dom'][0];
        if (dom.endsWith('\n')) {
          dom = '$dom\n';
        }

        return new BrowserTestJsonResult(
            _getOutcome(messagesByType), dom, events as List<dynamic>);
      }
    } catch (error) {
      // If something goes wrong, we know the content was not in the correct
      // JSON format. So we can't parse it.
      // The caller is responsible for falling back to the old way of
      // determining if a test failed.
    }

    return null;
  }

  static Expectation _getOutcome(Map<String, List<String>> messagesByType) {
    occured(String type) => messagesByType[type].length > 0;
    searchForMsg(List<String> types, String message) {
      return types.any((type) => messagesByType[type].contains(message));
    }

    // FIXME(kustermann,ricow): I think this functionality doesn't work in
    // test_controller.js: So far I haven't seen anything being reported on
    // "window.compilationerror"
    if (occured('window_compilationerror')) {
      return Expectation.compileTimeError;
    }

    if (occured('sync_exception') ||
        occured('window_onerror') ||
        occured('script_onerror')) {
      return Expectation.runtimeError;
    }

    if (messagesByType['dom'][0].contains('FAIL')) {
      return Expectation.runtimeError;
    }

    // We search for these messages in 'print' and 'message_received' because
    // the unittest implementation posts these messages using
    // "window.postMessage()" instead of the normal "print()" them.

    var isAsyncTest = searchForMsg(
        ['print', 'message_received'], 'unittest-suite-wait-for-done');
    var isAsyncSuccess =
        searchForMsg(['print', 'message_received'], 'unittest-suite-success') ||
            searchForMsg(['print', 'message_received'], 'unittest-suite-done');

    if (isAsyncTest) {
      if (isAsyncSuccess) {
        return Expectation.pass;
      }
      return Expectation.runtimeError;
    }

    var mainStarted =
        searchForMsg(['print', 'message_received'], 'dart-calling-main');
    var mainDone =
        searchForMsg(['print', 'message_received'], 'dart-main-done');

    if (mainStarted && mainDone) {
      return Expectation.pass;
    }
    return Expectation.fail;
  }
}

class BrowserCommandOutput extends CommandOutput
    with UnittestSuiteMessagesMixin {
  final BrowserTestOutput _result;
  final Expectation _rawOutcome;

  factory BrowserCommandOutput(Command command, BrowserTestOutput result) {
    String indent(String string, int numSpaces) {
      var spaces = new List.filled(numSpaces, ' ').join('');
      return string
          .replaceAll('\r\n', '\n')
          .split('\n')
          .map((line) => "$spaces$line")
          .join('\n');
    }

    String stdout = "";
    String stderr = "";
    Expectation outcome;

    var parsedResult =
        BrowserTestJsonResult.parseFromString(result.lastKnownMessage);
    if (parsedResult != null) {
      outcome = parsedResult.outcome;
    } else {
      // Old way of determining whether a test failed or passed.
      if (result.lastKnownMessage.contains("FAIL")) {
        outcome = Expectation.runtimeError;
      } else if (result.lastKnownMessage.contains("PASS")) {
        outcome = Expectation.pass;
      } else {
        outcome = Expectation.runtimeError;
      }
    }

    if (result.didTimeout) {
      if (result.delayUntilTestStarted != null) {
        stderr = "This test timed out. The delay until the test actually "
            "started was: ${result.delayUntilTestStarted}.";
      } else {
        stderr = "This test has not notified test.py that it started running.";
      }
    }

    if (parsedResult != null) {
      stdout = "events:\n${indent(prettifyJson(parsedResult.events), 2)}\n\n";
    } else {
      stdout = "message:\n${indent(result.lastKnownMessage, 2)}\n\n";
    }

    stderr = '$stderr\n\n'
        'BrowserOutput while running the test (* EXPERIMENTAL *):\n'
        'BrowserOutput.stdout:\n'
        '${indent(result.browserOutput.stdout.toString(), 2)}\n'
        'BrowserOutput.stderr:\n'
        '${indent(result.browserOutput.stderr.toString(), 2)}\n'
        '\n';
    return new BrowserCommandOutput._internal(
        command, result, outcome, encodeUtf8(stdout), encodeUtf8(stderr));
  }

  BrowserCommandOutput._internal(Command command, BrowserTestOutput result,
      this._rawOutcome, List<int> stdout, List<int> stderr)
      : _result = result,
        super(command, 0, result.didTimeout, stdout, stderr, result.duration,
            false, 0);

  Expectation result(TestCase testCase) {
    // Handle timeouts first.
    if (_result.didTimeout) {
      if (testCase.configuration.runtime == Runtime.ie11) {
        // TODO(28955): See http://dartbug.com/28955
        DebugLogger.warning("Timeout of ie11 on test ${testCase.displayName}");
        return Expectation.ignore;
      }
      return Expectation.timeout;
    }

    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Multitests are handled specially.
    if (testCase.hasRuntimeError) {
      if (_rawOutcome == Expectation.runtimeError) return Expectation.pass;
      return Expectation.missingRuntimeError;
    }

    return _negateOutcomeIfNegativeTest(_rawOutcome, testCase.isNegative);
  }
}

class AnalysisCommandOutput extends CommandOutput {
  // An error line has 8 fields that look like:
  // ERROR|COMPILER|MISSING_SOURCE|file:/tmp/t.dart|15|1|24|Missing source.
  static const int _errorLevel = 0;
  static const int _formattedError = 7;

  AnalysisCommandOutput(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, 0);

  Expectation result(TestCase testCase) {
    // TODO(kustermann): If we run the analyzer not in batch mode, make sure
    // that command.exitCodes matches 2 (errors), 1 (warnings), 0 (no warnings,
    // no errors)

    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Get the errors/warnings from the analyzer
    var errors = <String>[];
    var warnings = <String>[];
    parseAnalyzerOutput(errors, warnings);

    // Handle errors / missing errors
    if (testCase.expectCompileError) {
      if (errors.isNotEmpty) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }
    if (errors.isNotEmpty) {
      return Expectation.compileTimeError;
    }

    // Handle static warnings / missing static warnings
    if (testCase.hasStaticWarning) {
      if (warnings.isNotEmpty) {
        return Expectation.pass;
      }
      return Expectation.missingStaticWarning;
    }
    if (warnings.isNotEmpty) {
      return Expectation.staticWarning;
    }

    assert(errors.isEmpty && warnings.isEmpty);
    assert(!testCase.hasCompileError && !testCase.hasStaticWarning);
    return Expectation.pass;
  }

  void parseAnalyzerOutput(List<String> outErrors, List<String> outWarnings) {
    // Parse a line delimited by the | character using \ as an escape character
    // like:  FOO|BAR|FOO\|BAR|FOO\\BAZ as 4 fields: FOO BAR FOO|BAR FOO\BAZ
    List<String> splitMachineError(String line) {
      var field = new StringBuffer();
      var result = <String>[];
      var escaped = false;
      for (var i = 0; i < line.length; i++) {
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

    for (String line in decodeUtf8(super.stderr).split("\n")) {
      if (line.isEmpty) continue;

      List<String> fields = splitMachineError(line);
      // We only consider errors/warnings for files of interest.
      if (fields.length > _formattedError) {
        if (fields[_errorLevel] == 'ERROR') {
          outErrors.add(fields[_formattedError]);
        } else if (fields[_errorLevel] == 'WARNING') {
          outWarnings.add(fields[_formattedError]);
        }
        // OK to Skip error output that doesn't match the machine format.
      }
    }
  }
}

class VMCommandOutput extends CommandOutput with UnittestSuiteMessagesMixin {
  static const _dfeErrorExitCode = 252;
  static const _compileErrorExitCode = 254;
  static const _uncaughtExceptionExitCode = 255;

  VMCommandOutput(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time, int pid)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, pid);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (exitCode == _dfeErrorExitCode) return Expectation.dartkCrash;
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Multitests are handled specially.
    if (testCase.expectCompileError) {
      if (exitCode == _compileErrorExitCode) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }

    if (testCase.hasRuntimeError) {
      // TODO(kustermann): Do we consider a "runtimeError" only an uncaught
      // exception or does any nonzero exit code fullfil this requirement?
      if (exitCode != 0) {
        return Expectation.pass;
      }
      return Expectation.missingRuntimeError;
    }

    // The actual outcome depends on the exitCode.
    var outcome = Expectation.pass;
    if (exitCode == _compileErrorExitCode) {
      outcome = Expectation.compileTimeError;
    } else if (exitCode == _uncaughtExceptionExitCode) {
      outcome = Expectation.runtimeError;
    } else if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      outcome = Expectation.fail;
    }

    outcome = _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class CompilationCommandOutput extends CommandOutput {
  static const _crashExitCode = 253;

  CompilationCommandOutput(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, 0);

  Expectation result(TestCase testCase) {
    // Handle general crash/timeout detection.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) {
      var isWindows = io.Platform.operatingSystem == 'windows';
      var isBrowserTestCase =
          testCase.commands.any((command) => command is BrowserTestCommand);
      // TODO(26060) Dart2js batch mode hangs on Windows under heavy load.
      return (isWindows && isBrowserTestCase)
          ? Expectation.ignore
          : Expectation.timeout;
    }
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Handle dart2js specific crash detection
    if (exitCode == _crashExitCode ||
        exitCode == VMCommandOutput._compileErrorExitCode ||
        exitCode == VMCommandOutput._uncaughtExceptionExitCode) {
      return Expectation.crash;
    }

    // Multitests are handled specially.
    if (testCase.expectCompileError) {
      // Nonzero exit code of the compiler means compilation failed
      // TODO(kustermann): Do we have a special exit code in that case???
      if (exitCode != 0) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }

    // TODO(kustermann): This is a hack, remove it.
    if (testCase.hasRuntimeError && testCase.commands.length > 1) {
      // We expected to run the test, but we got an compile time error.
      // If the compilation succeeded, we wouldn't be in here!
      assert(exitCode != 0);
      return Expectation.compileTimeError;
    }

    var outcome =
        exitCode == 0 ? Expectation.pass : Expectation.compileTimeError;
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class KernelCompilationCommandOutput extends CompilationCommandOutput {
  KernelCompilationCommandOutput(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped);

  bool get canRunDependendCommands {
    // See [BatchRunnerProcess]: 0 means success, 1 means compile-time error.
    // TODO(asgerf): When the frontend supports it, continue running even if
    // there were compile-time errors. See kernel_sdk issue #18.
    return !hasCrashed && !hasTimedOut && exitCode == 0;
  }

  Expectation result(TestCase testCase) {
    Expectation result = super.result(testCase);
    if (result.canBeOutcomeOf(Expectation.crash)) {
      return Expectation.dartkCrash;
    } else if (result.canBeOutcomeOf(Expectation.timeout)) {
      return Expectation.dartkTimeout;
    } else if (result.canBeOutcomeOf(Expectation.compileTimeError)) {
      return Expectation.dartkCompileTimeError;
    }
    return result;
  }

  /// If the compiler was able to produce a Kernel IR file we want to run the
  /// result on the Dart VM. We therefore mark the [KernelCompilationCommand]
  /// as successful.
  ///
  /// This ensures we test that the DartVM produces correct CompileTime errors
  /// as it is supposed to for our test suites.
  bool get successful => canRunDependendCommands;
}

class JSCommandLineOutput extends CommandOutput
    with UnittestSuiteMessagesMixin {
  JSCommandLineOutput(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, 0);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    if (testCase.hasRuntimeError) {
      if (exitCode != 0) return Expectation.pass;
      return Expectation.missingRuntimeError;
    }

    var outcome = exitCode == 0 ? Expectation.pass : Expectation.runtimeError;
    outcome = _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class ScriptCommandOutput extends CommandOutput {
  final Expectation _result;

  ScriptCommandOutput(ScriptCommand command, this._result,
      String scriptExecutionInformation, Duration time)
      : super(command, 0, false, [], [], time, false, 0) {
    var lines = scriptExecutionInformation.split("\n");
    diagnostics.addAll(lines);
  }

  Expectation result(TestCase testCase) => _result;

  bool get canRunDependendCommands => _result == Expectation.pass;

  bool get successful => _result == Expectation.pass;
}

CommandOutput createCommandOutput(Command command, int exitCode, bool timedOut,
    List<int> stdout, List<int> stderr, Duration time, bool compilationSkipped,
    [int pid = 0]) {
  if (command is ContentShellCommand) {
    return new ContentShellCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is BrowserTestCommand) {
    return new HtmlBrowserCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is AnalysisCommand) {
    return new AnalysisCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is VmCommand) {
    return new VMCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is KernelCompilationCommand) {
    return new KernelCompilationCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is AdbPrecompilationCommand) {
    return new VMCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is CompilationCommand) {
    if (command.displayName == 'precompiler' ||
        command.displayName == 'app_jit') {
      return new VMCommandOutput(
          command, exitCode, timedOut, stdout, stderr, time, pid);
    }
    return new CompilationCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is JSCommandlineCommand) {
    return new JSCommandLineOutput(
        command, exitCode, timedOut, stdout, stderr, time);
  }

  return new CommandOutput(command, exitCode, timedOut, stdout, stderr, time,
      compilationSkipped, pid);
}

class UnittestSuiteMessagesMixin {
  bool _isAsyncTest(String testOutput) {
    return testOutput.contains("unittest-suite-wait-for-done");
  }

  bool _isAsyncTestSuccessful(String testOutput) {
    return testOutput.contains("unittest-suite-success");
  }

  Expectation _negateOutcomeIfIncompleteAsyncTest(
      Expectation outcome, String testOutput) {
    // If this is an asynchronous test and the asynchronous operation didn't
    // complete successfully, it's outcome is Expectation.FAIL.
    // TODO: maybe we should introduce a AsyncIncomplete marker or so
    if (outcome == Expectation.pass) {
      if (_isAsyncTest(testOutput) && !_isAsyncTestSuccessful(testOutput)) {
        return Expectation.fail;
      }
    }
    return outcome;
  }
}
