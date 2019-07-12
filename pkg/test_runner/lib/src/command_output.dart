// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;

import 'package:status_file/expectation.dart';
import 'package:test_runner/src/test_file.dart';

import 'browser_controller.dart';
import 'command.dart';
import 'configuration.dart';
import 'process_queue.dart';
import 'test_case.dart';
import 'test_progress.dart';
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

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (_didFail(testCase)) return Expectation.fail;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    return Expectation.pass;
  }

  bool get hasCrashed {
    // dart2js exits with code 253 in case of unhandled exceptions.
    // The dart binary exits with code 253 in case of an API error such
    // as an invalid snapshot file.
    // The batch mode can also exit 253 (unhandledCompilerExceptionExitCode).
    // In either case an exit code of 253 is considered a crash.
    if (exitCode == unhandledCompilerExceptionExitCode) return true;
    if (exitCode == parseFailExitCode) return false;
    if (hasTimedOut) return false;
    if (io.Platform.isWindows) {
      // The VM uses std::abort to terminate on asserts.
      // std::abort terminates with exit code 3 on Windows.
      if (exitCode == 3) return true;

      // When VM is built with Crashpad support we get STATUS_FATAL_APP_EXIT
      // for all crashes that Crashpad has intercepted.
      if (exitCode == 0x40000015) return true;

      // If a program receives an uncaught system exception, the program
      // terminates with the exception code as exit code.
      // https://msdn.microsoft.com/en-us/library/cc704588.aspx lists status
      // codes basically saying that codes starting with 0xC0, 0x80 or 0x40
      // are crashes, so look at the 4 most significant bits in 32-bit-space
      // make sure its either 0b1100, 0b1000 or 0b0100.
      int masked = (exitCode & 0xF0000000) >> 28;
      return (exitCode < 0) && (masked >= 4) && ((masked & 3) == 0);
    }
    return exitCode < 0;
  }

  bool get hasCoreDump {
    // Unhandled dart exceptions don't produce crashdumps.
    return hasCrashed && exitCode != 253;
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

  /// Called when producing output for a test failure to describe this output.
  void describe(TestCase testCase, Progress progress, OutputWriter output) {
    output.subsection("exit code");
    output.write(exitCode.toString());

    if (diagnostics.isNotEmpty) {
      output.subsection("diagnostics");
      output.writeAll(diagnostics);
    }

    if (stdout.isNotEmpty) {
      output.subsection("stdout");
      output.writeAll(decodeLines(stdout));
    }

    if (stderr.isNotEmpty) {
      output.subsection("stderr");
      output.writeAll(decodeLines(stderr));
    }
  }
}

class BrowserTestJsonResult {
  static const _allowedTypes = [
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
    void validate(String message, bool isValid) {
      if (!isValid) {
        throw "InvalidFormat sent from browser driving page: $message:\n\n"
            "$content";
      }
    }

    try {
      var events = jsonDecode(content);
      if (events != null) {
        validate("Message must be a List", events is List);

        var messagesByType = {for (var type in _allowedTypes) type: <String>[]};

        for (var entry in events) {
          validate("Entry must be a Map", entry is Map);

          var type = entry['type'];
          validate("'type' must be a String", type is String);
          validate("'type' has to be in $_allowedTypes.",
              _allowedTypes.contains(type));

          var value = entry['value'];
          validate("'value' must be a String", value is String);

          var timestamp = entry['timestamp'];
          validate("'timestamp' must be a number", timestamp is num);

          var stackTrace = entry['stack_trace'];
          if (stackTrace != null) {
            validate("'stack_trace' must be a String", stackTrace is String);
          }

          messagesByType[type].add(value as String);
        }
        validate("The message must have exactly one 'dom' entry.",
            messagesByType['dom'].length == 1);

        var dom = messagesByType['dom'][0];
        if (dom.endsWith('\n')) {
          dom = '$dom\n';
        }

        return BrowserTestJsonResult(
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
    occurred(String type) => messagesByType[type].isNotEmpty;

    searchForMsg(List<String> types, String message) {
      return types.any((type) => messagesByType[type].contains(message));
    }

    // FIXME(kustermann,ricow): I think this functionality doesn't work in
    // test_controller.js: So far I haven't seen anything being reported on
    // "window.compilationerror"
    if (occurred('window_compilationerror')) {
      return Expectation.compileTimeError;
    }

    if (occurred('sync_exception') ||
        occurred('window_onerror') ||
        occurred('script_onerror')) {
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
    with _UnittestSuiteMessagesMixin {
  final BrowserTestJsonResult _jsonResult;
  final BrowserTestOutput _result;
  final Expectation _rawOutcome;

  factory BrowserCommandOutput(Command command, BrowserTestOutput result) {
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

    var stderr = "";
    if (result.didTimeout) {
      if (result.delayUntilTestStarted != null) {
        stderr = "This test timed out. The delay until the test actually "
            "started was: ${result.delayUntilTestStarted}.";
      } else {
        stderr = "This test did not notify test.py that it started running.";
      }
    }

    return BrowserCommandOutput._internal(command, result, outcome,
        parsedResult, encodeUtf8(""), encodeUtf8(stderr));
  }

  BrowserCommandOutput._internal(Command command, BrowserTestOutput result,
      this._rawOutcome, this._jsonResult, List<int> stdout, List<int> stderr)
      : _result = result,
        super(command, 0, result.didTimeout, stdout, stderr, result.duration,
            false, 0);

  Expectation result(TestCase testCase) {
    // Handle timeouts first.
    if (_result.didTimeout) {
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

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    // Handle timeouts first.
    if (_result.didTimeout) {
      return Expectation.timeout;
    }

    if (hasNonUtf8) return Expectation.nonUtf8Error;
    return _rawOutcome;
  }

  void describe(TestCase testCase, Progress progress, OutputWriter output) {
    if (_jsonResult != null) {
      _describeEvents(progress, output);
    } else {
      // We couldn't parse the events, so fallback to showing the last message.
      output.section("Last message");
      output.write(_result.lastKnownMessage);
    }

    super.describe(testCase, progress, output);

    if (_result.browserOutput.stdout.isNotEmpty) {
      output.subsection("Browser stdout");
      output.write(_result.browserOutput.stdout.toString());
    }

    if (_result.browserOutput.stderr.isNotEmpty) {
      output.subsection("Browser stderr");
      output.write(_result.browserOutput.stderr.toString());
    }
  }

  void _describeEvents(Progress progress, OutputWriter output) {
    // Always show the error events since those are most useful.
    var showedError = false;

    void _showError(String header, event) {
      output.subsection(header);
      output.write((event["value"] as String).trim());
      if (event["stack_trace"] != null) {
        var stack = (event["stack_trace"] as String).trim().split("\n");
        output.writeAll(stack);
      }

      showedError = true;
    }

    for (var event in _jsonResult.events) {
      if (event["type"] == "sync_exception") {
        _showError("Runtime error", event);
      } else if (event["type"] == "window_onerror") {
        _showError("Runtime window.onerror", event);
      }
    }

    // Show the events unless the above error was sufficient.
    // TODO(rnystrom): Let users enable or disable this explicitly?
    if (showedError &&
        progress != Progress.buildbot &&
        progress != Progress.verbose) {
      return;
    }

    output.subsection("Events");
    for (var event in _jsonResult.events) {
      switch (event["type"] as String) {
        case "debug":
          output.write('- debug "${event["value"] as String}"');
          break;

        case "dom":
          output.write('- dom\n${indent(event["value"] as String, 2)}');
          break;

        case "print":
          output.write('- print "${event["value"] as String}"');
          break;

        case "window_onerror":
          var value = event["value"] as String;
          value = indent(value.trim(), 2);
          value = "- " + value.substring(2);
          output.write(value);
          break;

        default:
          output.write("- ${prettifyJson(event)}");
      }
    }
  }
}

class AnalysisCommandOutput extends CommandOutput with _StaticErrorOutput {
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

  @override
  void describe(TestCase testCase, Progress progress, OutputWriter output) {
    if (testCase.testFile.isStaticErrorTest) {
      _validateExpectedErrors(testCase, output);
    }

    if (!testCase.testFile.isStaticErrorTest || progress == Progress.verbose) {
      super.describe(testCase, progress, output);
    }
  }

  Expectation result(TestCase testCase) {
    // TODO(kustermann): If we run the analyzer not in batch mode, make sure
    // that command.exitCodes matches 2 (errors), 1 (warnings), 0 (no warnings,
    // no errors)

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
    }

    // Handle negative.
    if (testCase.isNegative) {
      return errors.isNotEmpty
          ? Expectation.pass
          : Expectation.missingCompileTimeError;
    }

    // Handle errors / missing errors.
    if (testCase.hasCompileError) {
      if (errors.isNotEmpty) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }
    if (errors.isNotEmpty) {
      return Expectation.compileTimeError;
    }

    // Handle static warnings / missing static warnings.
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

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    // TODO(kustermann): If we run the analyzer not in batch mode, make sure
    // that command.exitCodes matches 2 (errors), 1 (warnings), 0 (no warnings,
    // no errors)

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
    }

    if (errors.isNotEmpty) {
      return Expectation.compileTimeError;
    }
    if (warnings.isNotEmpty) {
      return Expectation.staticWarning;
    }
    return Expectation.pass;
  }

  /// Parses the machine-readable output of analyzer, which looks like:
  ///
  ///     ERROR|STATIC_TYPE_WARNING|SOME_ERROR_CODE|/path/to/some_test.dart|9|26|1|Error message.
  ///
  /// Pipes can be escaped with backslashes:
  ///
  ///     FOO|BAR|FOO\|BAR|FOO\\BAZ
  ///
  /// Is parsed as:
  ///
  ///     FOO BAR FOO|BAR FOO\BAZ
  @override
  void _parseErrors() {
    List<String> splitMachineError(String line) {
      var field = StringBuffer();
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
          field = StringBuffer();
          continue;
        }
        field.write(c);
      }
      result.add(field.toString());
      return result;
    }

    for (var line in decodeUtf8(stderr).split("\n")) {
      if (line.isEmpty) continue;

      var fields = splitMachineError(line);

      // Lines without enough fields are other output we don't care about.
      if (fields.length >= 8) {
        var severity = fields[0];
        var errorCode = "${fields[1]}.${fields[2]}";
        var line = int.parse(fields[4]);
        var column = int.parse(fields[5]);
        var length = int.parse(fields[6]);

        var error = StaticError(
            line: line, column: column, length: length, code: errorCode);

        if (severity == 'ERROR') {
          addError(error);
        } else if (severity == 'WARNING') {
          addWarning(error);
        }
      }
    }
  }
}

class CompareAnalyzerCfeCommandOutput extends CommandOutput {
  CompareAnalyzerCfeCommandOutput(
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
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    if (exitCode != 0) return Expectation.fail;
    for (var line in decodeUtf8(stdout).split('\n')) {
      if (line.contains('No differences found')) return Expectation.pass;
      if (line.contains('Differences found')) return Expectation.fail;
    }
    return Expectation.fail;
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    if (exitCode != 0) return Expectation.fail;
    for (var line in decodeUtf8(stdout).split('\n')) {
      if (line.contains('No differences found')) return Expectation.pass;
      if (line.contains('Differences found')) return Expectation.fail;
    }
    return Expectation.fail;
  }
}

class SpecParseCommandOutput extends CommandOutput {
  SpecParseCommandOutput(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, 0);

  bool get hasSyntaxError => exitCode == parseFailExitCode;

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    if (testCase.hasCompileError) {
      if (testCase.hasSyntaxError) {
        // A syntax error is expected.
        return hasSyntaxError
            ? Expectation.pass
            : Expectation.missingSyntaxError;
      } else {
        // A non-syntax compile-time error is expected by the test, so a run
        // with no failures is a successful run. A run with failures is an
        // actual (but unexpected) syntax error.
        return exitCode == 0 ? Expectation.pass : Expectation.syntaxError;
      }
    }

    // No compile-time errors expected (including: no syntax errors).
    return exitCode == 0 ? Expectation.pass : Expectation.syntaxError;
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (hasSyntaxError) return Expectation.syntaxError;
    if (exitCode != 0) return Expectation.syntaxError;
    return Expectation.pass;
  }
}

class VMCommandOutput extends CommandOutput with _UnittestSuiteMessagesMixin {
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
    if (testCase.hasCompileError) {
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

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (exitCode == _dfeErrorExitCode) return Expectation.dartkCrash;
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // The actual outcome depends on the exitCode.
    if (exitCode == _compileErrorExitCode) return Expectation.compileTimeError;
    if (exitCode == _uncaughtExceptionExitCode) return Expectation.runtimeError;
    if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      return Expectation.fail;
    }
    var testOutput = decodeUtf8(stdout);
    if (_isAsyncTest(testOutput) && !_isAsyncTestSuccessful(testOutput)) {
      return Expectation.fail;
    }
    return Expectation.pass;
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

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  /// This code can return Expectation.ignore - we may want to fix that.
  Expectation realResult(TestCase testCase) {
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
    if (exitCode != 0) return Expectation.compileTimeError;
    return Expectation.pass;
  }

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
    if (testCase.hasCompileError) {
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

class DevCompilerCommandOutput extends CommandOutput {
  DevCompilerCommandOutput(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped,
      int pid)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, pid);

  Expectation result(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Handle errors / missing errors
    if (testCase.hasCompileError) {
      return exitCode == 0
          ? Expectation.missingCompileTimeError
          : Expectation.pass;
    }

    var outcome =
        exitCode == 0 ? Expectation.pass : Expectation.compileTimeError;
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (exitCode != 0) return Expectation.compileTimeError;
    return Expectation.pass;
  }
}

class VMKernelCompilationCommandOutput extends CompilationCommandOutput {
  VMKernelCompilationCommandOutput(
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
    // TODO(kustermann): Currently the batch mode runner (which can be found
    // in `test_runner.dart:BatchRunnerProcess`) does not really distinguish
    // between different kinds of failures and will mark a failed
    // compilation to just an exit code of "1".  So we treat all `exitCode ==
    // 1`s as compile-time errors as well.
    const int kBatchModeCompileTimeErrorExit = 1;

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.dartkCrash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // If the frontend had an uncaught exception, then we'll consider this a
    // crash.
    if (exitCode == VMCommandOutput._uncaughtExceptionExitCode) {
      return Expectation.dartkCrash;
    }

    // Multitests are handled specially.
    if (testCase.hasCompileError) {
      if (exitCode == VMCommandOutput._compileErrorExitCode ||
          exitCode == kBatchModeCompileTimeErrorExit) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }

    // The actual outcome depends on the exitCode.
    var outcome = Expectation.pass;
    if (exitCode == VMCommandOutput._compileErrorExitCode ||
        exitCode == kBatchModeCompileTimeErrorExit) {
      outcome = Expectation.compileTimeError;
    } else if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      outcome = Expectation.fail;
    }

    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    // TODO(kustermann): Currently the batch mode runner (which can be found
    // in `test_runner.dart:BatchRunnerProcess`) does not really distinguish
    // between different kinds of failures and will mark a failed
    // compilation to just an exit code of "1".  So we treat all `exitCode ==
    // 1`s as compile-time errors as well.
    const int kBatchModeCompileTimeErrorExit = 1;

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.dartkCrash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // If the frontend had an uncaught exception, then we'll consider this a
    // crash.
    if (exitCode == VMCommandOutput._uncaughtExceptionExitCode) {
      return Expectation.dartkCrash;
    }

    // Multitests are handled specially.

    if (exitCode == VMCommandOutput._compileErrorExitCode ||
        exitCode == kBatchModeCompileTimeErrorExit) {
      return Expectation.compileTimeError;
    }
    if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      return Expectation.fail;
    }
    return Expectation.pass;
  }

  /// If the compiler was able to produce a Kernel IR file we want to run the
  /// result on the Dart VM. We therefore mark the [VMKernelCompilationCommand]
  /// as successful.
  ///
  /// This ensures we test that the DartVM produces correct CompileTime errors
  /// as it is supposed to for our test suites.
  bool get successful => canRunDependendCommands;
}

class JSCommandLineOutput extends CommandOutput
    with _UnittestSuiteMessagesMixin {
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

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    if (exitCode != 0) return Expectation.runtimeError;
    var output = decodeUtf8(stdout);
    if (_isAsyncTest(output) && !_isAsyncTestSuccessful(output)) {
      return Expectation.fail;
    }
    return Expectation.pass;
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
  Expectation realResult(TestCase testCase) => _result;

  bool get canRunDependendCommands => _result == Expectation.pass;

  bool get successful => _result == Expectation.pass;
}

class FastaCommandOutput extends CompilationCommandOutput
    with _StaticErrorOutput {
  /// Matches the first line of a Fasta error message. Fasta prints errors to
  /// stdout that look like:
  ///
  ///     tests/language_2/some_test.dart:7:21: Error: Some message.
  ///     Try fixing the code to be less bad.
  ///       var _ = <int>[if (1) 2];
  ///                    ^
  ///
  /// The test runner only validates the main error message, and not the
  /// suggested fixes, so we only parse the first line.
  static final _errorRegexp =
      RegExp(r"^([^:]+):(\d+):(\d+): Error: (.*)$", multiLine: true);

  FastaCommandOutput(
      Command command,
      int exitCode,
      bool hasTimedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, hasTimedOut, stdout, stderr, time,
            compilationSkipped);

  @override
  void _parseErrors() {
    for (var match in _errorRegexp.allMatches(decodeUtf8(stdout))) {
      var line = int.parse(match.group(2));
      var column = int.parse(match.group(3));
      var message = match.group(4);
      addError(StaticError(line: line, column: column, message: message));
    }
  }
}

CommandOutput createCommandOutput(Command command, int exitCode, bool timedOut,
    List<int> stdout, List<int> stderr, Duration time, bool compilationSkipped,
    [int pid = 0]) {
  if (command is AnalysisCommand) {
    return AnalysisCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is CompareAnalyzerCfeCommand) {
    return CompareAnalyzerCfeCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is SpecParseCommand) {
    return SpecParseCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is VmCommand) {
    return VMCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is VMKernelCompilationCommand) {
    return VMKernelCompilationCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is AdbPrecompilationCommand) {
    return VMCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is FastaCompilationCommand) {
    return FastaCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is CompilationCommand) {
    if (command.displayName == 'precompiler' ||
        command.displayName == 'app_jit') {
      return VMCommandOutput(
          command, exitCode, timedOut, stdout, stderr, time, pid);
    } else if (command.displayName == 'dartdevc') {
      return DevCompilerCommandOutput(command, exitCode, timedOut, stdout,
          stderr, time, compilationSkipped, pid);
    }
    return CompilationCommandOutput(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is JSCommandlineCommand) {
    return JSCommandLineOutput(
        command, exitCode, timedOut, stdout, stderr, time);
  }

  return CommandOutput(command, exitCode, timedOut, stdout, stderr, time,
      compilationSkipped, pid);
}

/// Mixin for outputs from a command that implement a Dart front end which
/// reports static errors.
mixin _StaticErrorOutput on CommandOutput {
  /// Reported static errors, parsed from [stderr].
  List<StaticError> get errors {
    if (!_parsedErrors) {
      _parseErrors();
      _parsedErrors = true;
    }
    return _errors;
  }

  /// Don't access this from outside of the mixin. It gets populated lazily by
  /// going through the [errors] getter.
  final List<StaticError> _errors = [];

  /// Reported static warnings, parsed from [stderr].
  List<StaticError> get warnings {
    if (!_parsedErrors) {
      _parseErrors();
      _parsedErrors = true;
    }
    return _warnings;
  }

  /// Don't access this from outside of the mixin. It gets populated lazily by
  /// going through the [warnings] getter.
  final List<StaticError> _warnings = [];

  bool _parsedErrors = false;

  @override
  void describe(TestCase testCase, Progress progress, OutputWriter output) {
    if (testCase.testFile.isStaticErrorTest) {
      _validateExpectedErrors(testCase, output);
    }

    if (!testCase.testFile.isStaticErrorTest || progress == Progress.verbose) {
      super.describe(testCase, progress, output);
    }
  }

  Expectation result(TestCase testCase) {
    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
    }

    return super.result(testCase);
  }

  Expectation realResult(TestCase testCase) {
    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
    }

    return super.realResult(testCase);
  }

  /// A subclass should override this to parse the command's output for any
  /// reported errors and warnings.
  ///
  /// It should read [stderr] and [stdout] and call [addError] and [addWarning].
  void _parseErrors();

  void addError(StaticError error) {
    _errors.add(error);
  }

  void addWarning(StaticError error) {
    _warnings.add(error);
  }

  /// Compare the actual errors produced to the expected static errors parsed
  /// from the test file.
  ///
  /// Returns [Expectation.pass] if all expected errors were correctly
  /// reported.
  ///
  /// If [writer] is given, outputs a description of any error mismatches.
  Expectation _validateExpectedErrors(TestCase testCase,
      [OutputWriter writer]) {
    // Filter out errors that aren't for this configuration.
    var expected = testCase.testFile.expectedErrors
        .where((error) =>
            testCase.configuration.compiler == Compiler.dart2analyzer
                ? error.isAnalyzer
                : error.isCfe)
        .toList();
    var actual = errors.toList();

    // Don't require the test or analyzer to output in any specific order.
    expected.sort();
    actual.sort();

    writer?.subsection("incorrect static errors");

    var success = expected.length == actual.length;
    for (var i = 0; i < expected.length && i < actual.length; i++) {
      var differences = expected[i].describeDifferences(actual[i]);
      if (differences == null) continue;

      if (writer != null) {
        writer.write(actual[i].location);
        for (var difference in differences) {
          writer.write("- $difference");
        }
        writer.separator();
      }

      success = false;
    }

    if (writer != null) {
      writer.subsection("missing expected static errors");
      for (var i = actual.length; i < expected.length; i++) {
        writer.write(expected[i].toString());
        writer.separator();
      }

      writer.subsection("reported unexpected static errors");
      for (var i = expected.length; i < actual.length; i++) {
        writer.write(actual[i].toString());
        writer.separator();
      }
    }

    // TODO(rnystrom): Is there a better expectation we can use?
    return success ? Expectation.pass : Expectation.missingCompileTimeError;
  }
}

mixin _UnittestSuiteMessagesMixin {
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
