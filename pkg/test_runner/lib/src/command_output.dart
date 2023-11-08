// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;

import 'package:dart2js_tools/deobfuscate_stack_trace.dart';
import 'package:status_file/expectation.dart';
import 'package:test_runner/src/static_error.dart';

import 'browser_controller.dart';
import 'command.dart';
import 'configuration.dart';
import 'path.dart';
import 'process_queue.dart';
import 'terminal.dart';
import 'test_case.dart';
import 'test_progress.dart';
import 'utils.dart';

/// CommandOutput records the output of a completed command: the process's exit
/// code, the standard output and standard error, whether the process timed out,
/// and the time the process took to run. It does not contain a pointer to the
/// [TestCase] this is the output of, so some functions require the test case
/// to be passed as an argument.
class CommandOutput {
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
    if (_didFail(testCase)) return Expectation.fail;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    return Expectation.pass;
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  Expectation realResult(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (_didFail(testCase)) return Expectation.fail;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

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
      var masked = (exitCode & 0xF0000000) >> 28;
      return (exitCode < 0) && (masked >= 4) && ((masked & 3) == 0);
    }
    return exitCode < 0;
  }

  bool get hasCoreDump {
    // Unhandled dart exceptions don't produce crashdumps.
    return hasCrashed && exitCode != 253;
  }

  bool _didFail(TestCase testCase) => exitCode != 0 && !hasCrashed;

  bool get canRunDependentCommands {
    // TODO(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  bool get successful {
    // TODO(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  bool get hasNonUtf8 => exitCode == nonUtfFakeExitCode;

  /// Whether the command's output was too long and was truncated.
  bool get truncatedOutput => exitCode == truncatedFakeExitCode;

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

  static BrowserTestJsonResult? parseFromString(String content) {
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
        // TODO(srawlins): This will promote `events` in null safety.
        var eventList = events as List<dynamic>;

        var messagesByType = {
          for (var type in _allowedTypes) type: <String?>[]
        };

        for (var entry in eventList) {
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

          messagesByType[type]!.add(value as String?);
        }
        validate("The message must have exactly one 'dom' entry.",
            messagesByType['dom']!.length == 1);

        var dom = messagesByType['dom']![0]!;
        if (dom.endsWith('\n')) {
          dom = '$dom\n';
        }

        return BrowserTestJsonResult(
            _getOutcome(messagesByType), dom, eventList);
      }
    } catch (error) {
      // If something goes wrong, we know the content was not in the correct
      // JSON format. So we can't parse it.
      // The caller is responsible for falling back to the old way of
      // determining if a test failed.
    }

    return null;
  }

  static Expectation _getOutcome(Map<String, List<String?>> messagesByType) {
    occurred(String type) => messagesByType[type]!.isNotEmpty;

    searchForMsg(List<String> types, String message) {
      return types.any((type) => messagesByType[type]!.contains(message));
    }

    // TODO(kustermann,ricow): I think this functionality doesn't work in
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

    if (messagesByType['dom']![0]!.contains('FAIL')) {
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
  final BrowserTestJsonResult? _jsonResult;
  final BrowserTestOutput _result;
  final Expectation _outcome;

  /// Directory that is being served under `http:/.../root_build/` to browser
  /// tests.
  final String _buildDirectory;

  factory BrowserCommandOutput(
      BrowserTestCommand command, BrowserTestOutput result) {
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

    return BrowserCommandOutput._internal(
        command,
        result,
        outcome,
        parsedResult,
        command.configuration.buildDirectory,
        utf8.encode(""),
        utf8.encode(stderr));
  }

  BrowserCommandOutput._internal(
      Command command,
      BrowserTestOutput result,
      this._outcome,
      this._jsonResult,
      this._buildDirectory,
      List<int> stdout,
      List<int> stderr)
      : _result = result,
        super(command, 0, result.didTimeout, stdout, stderr, result.duration,
            false, 0);

  @override
  Expectation result(TestCase testCase) {
    // Handle timeouts first.
    if (_result.didTimeout) {
      return Expectation.timeout;
    }

    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    // Multitests are handled specially.
    if (testCase.hasRuntimeError) {
      if (_outcome == Expectation.runtimeError) return Expectation.pass;
      return Expectation.missingRuntimeError;
    }

    return _outcome;
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  @override
  Expectation realResult(TestCase testCase) {
    // Handle timeouts first.
    if (_result.didTimeout) {
      return Expectation.timeout;
    }

    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;
    return _outcome;
  }

  @override
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
    var errorShown = false;

    void showError(String header, event) {
      output.subsection(header);
      var value = event["value"] as String?;
      if (event["stack_trace"] != null) {
        value = '$value\n${event["stack_trace"]}';
      }
      errorShown = true;
      output.write(value);

      // Skip deobfuscation if there is no indication that there is a stack
      // trace in the string value.
      if (!value!.contains(RegExp('\\.js:'))) return;
      var stringStack = value
          // Convert `http:` URIs to relative `file:` URIs.
          .replaceAll(RegExp('http://[^/]*/root_build/'), '$_buildDirectory/')
          .replaceAll(RegExp('http://[^/]*/root_dart/'), '')
          // Remove query parameters (seen in .html URIs).
          .replaceAll(RegExp('\\?[^:\n]*:'), ':');
      // TODO(sigmund): change internal deobfuscation code to avoid spurious
      // error messages when files do not have a corresponding source-map.
      _deobfuscateAndWriteStack(stringStack, output);
    }

    for (var event in _jsonResult!.events) {
      if (event["type"] == "sync_exception") {
        showError("Runtime error", event);
      } else if (event["type"] == "window_onerror") {
        showError("Runtime window.onerror", event);
      }
    }

    // Show the events unless the above error was sufficient.
    // TODO(rnystrom): Let users enable or disable this explicitly?
    if (errorShown &&
        progress != Progress.buildbot &&
        progress != Progress.verbose) {
      return;
    }

    output.subsection("Events");
    for (var event in _jsonResult!.events) {
      switch (event["type"] as String?) {
        case "debug":
          output.write('- debug "${event["value"]}"');
          break;

        case "dom":
          output.write('- dom\n${indent(event["value"] as String, 2)}');
          break;

        case "print":
          output.write('- print "${event["value"]}"');
          break;

        case "window_onerror":
          var value = event["value"] as String;
          value = indent(value.trim(), 2);
          value = "- ${value.substring(2)}";
          output.write(value);
          break;

        default:
          output.write(
              "- ${const JsonEncoder.withIndent('      ').convert(event)}");
      }
    }
  }
}

/// A parsed analyzer error diagnostic.
class AnalyzerError implements Comparable<AnalyzerError> {
  /// The set of static warnings which must be expected in a test. Any warning
  /// not specified here which is reported by the analyzer does not need to be
  /// expected, and never causes a test to fail.
  static const Set<String> _specifiedWarnings = {
    'dead_null_aware_expression',
    'invalid_null_aware_operator',
    'missing_enum_constant_in_switch',
    'unnecessary_non_null_assertion',
    'unnecessary_null_assert_pattern',
    'unnecessary_null_check_pattern',
  };

  /// The set of hints which must be expected in a test. Any hint not specified
  /// here which is reported by the analyzer does not need to be expected, and
  /// never causes a test to fail.
  static const Set<String> _specifiedHints = {
    'unreachable_switch_case',
  };

  /// Parses all errors from analyzer [stdout] output.
  static List<AnalyzerError> parseStdout(String stdout) {
    var result = <AnalyzerError>[];

    var jsonData = json.decode(stdout) as Map<String, dynamic>;
    var version = jsonData['version'];
    if (version != 1) {
      DebugLogger.error('Unexpected analyzer JSON data version: $version');
      throw UnimplementedError();
    }

    for (var diagnostic in jsonData['diagnostics'] as List<dynamic>) {
      var diagnosticMap = diagnostic as Map<String, dynamic>;

      var code = diagnosticMap['code'] as String;
      var type = diagnosticMap['type'] as String?;

      if (type == 'HINT' && !_specifiedHints.contains(code)) {
        // The analyzer can report hints which do not need to be expected in
        // the test source. These can be ignored.
        // TODO(srawlins): Hints will start to change to be warnings. There are
        // some warnings produced now which must be expected. See
        // [StaticError._analyzerWarningCodes]. When we change hints to
        // warnings, we will need to ignore them here.
        continue;
      }

      if (type == 'STATIC_WARNING' && !_specifiedWarnings.contains(code)) {
        continue;
      }

      if (type == 'LINT') continue;

      var errorCode = '$type.${code.toUpperCase()}';

      var error = _parse(
          diagnosticMap, diagnosticMap['problemMessage'] as String, errorCode);
      result.add(error);

      var contextMessages = diagnosticMap['contextMessages'] as List<dynamic>?;
      for (var contextMessage in contextMessages ?? const []) {
        var contextMessageMap = contextMessage as Map<String, dynamic>;
        error.contextMessages.add(
            _parse(contextMessageMap, contextMessageMap['message'] as String));
      }
    }

    return result;
  }

  static AnalyzerError _parse(Map<String, dynamic> diagnostic, String message,
      [String? errorCode]) {
    var location = diagnostic['location'] as Map<String, dynamic>;

    var range = location['range'] as Map<String, dynamic>;
    var start = range['start'] as Map<String, dynamic>;
    var end = range['end'] as Map<String, dynamic>;
    return AnalyzerError._(
        severity: diagnostic['severity'] as String? ?? '',
        errorCode: errorCode ?? '',
        file: location['file'] as String,
        message: message,
        line: start['line'] as int,
        column: start['column'] as int,
        length: (end['offset'] as int) - (start['offset'] as int));
  }

  final String severity;
  final String errorCode;
  final String file;
  final String message;
  final int line;
  final int column;
  final int length;

  final List<AnalyzerError> contextMessages = [];

  AnalyzerError._(
      {this.severity = '',
      this.errorCode = '',
      required this.file,
      required this.message,
      required this.line,
      required this.column,
      required this.length});

  @override
  int compareTo(AnalyzerError other) {
    if (file != other.file) return file.compareTo(other.file);
    if (line != other.line) return line.compareTo(other.line);
    if (column != other.column) return column.compareTo(other.column);
    if (length != other.length) return length.compareTo(other.length);
    if (severity != other.severity) return severity.compareTo(other.severity);
    if (errorCode != other.errorCode) {
      return errorCode.compareTo(other.errorCode);
    }
    return message.compareTo(other.message);
  }
}

class AnalysisCommandOutput extends CommandOutput with _StaticErrorOutput {
  static void parseErrors(
    String stdout,
    List<StaticError> errors, [
    List<StaticError>? warnings,
  ]) {
    StaticError convert(AnalyzerError error) {
      var staticError = StaticError(ErrorSource.analyzer, error.errorCode,
          line: error.line, column: error.column, length: error.length);

      for (var context in error.contextMessages) {
        // TODO(rnystrom): Include these when static error tests get support
        // for errors/context in other files.
        if (context.file != error.file) {
          DebugLogger.warning(
              "Context messages in other files not currently supported.");
          continue;
        }

        staticError.contextMessages.add(StaticError(
            ErrorSource.context, context.message,
            line: context.line,
            column: context.column,
            length: context.length));
      }

      return staticError;
    }

    // Parse as Analyzer errors and then convert them to the StaticError objects
    // the static error tests expect.
    for (var diagnostic in AnalyzerError.parseStdout(stdout)) {
      if (diagnostic.severity == 'ERROR') {
        errors.add(convert(diagnostic));
      } else if (warnings != null &&
          (diagnostic.severity == 'WARNING' || diagnostic.severity == 'INFO')) {
        warnings.add(convert(diagnostic));
      }
    }
  }

  /// If the stdout of analyzer could not be parsed as valid JSON, this will be
  /// the stdout as a string instead. Otherwise it will be null.
  String? get invalidJsonStdout {
    if (!_parsedErrors) {
      _parseErrors();
      _parsedErrors = true;
    }

    return _invalidJsonStdout;
  }

  String? _invalidJsonStdout;

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
  Expectation result(TestCase testCase) {
    // TODO(kustermann): If we run the analyzer not in batch mode, make sure
    // that command.exitCodes matches 2 (errors), 1 (warnings), 0 (no warnings,
    // no errors)

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    if (invalidJsonStdout != null) return Expectation.fail;

    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
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
  @override
  Expectation realResult(TestCase testCase) {
    // TODO(kustermann): If we run the analyzer not in batch mode, make sure
    // that command.exitCodes matches 2 (errors), 1 (warnings), 0 (no warnings,
    // no errors)

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    if (invalidJsonStdout != null) return Expectation.fail;

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

  @override
  void describe(TestCase testCase, Progress progress, OutputWriter output) {
    if (invalidJsonStdout != null) {
      output.subsection("analyzer json parse result");
      output.write("- parse failed");
      output.subsection("invalid analyzer json");
      super.describe(testCase, progress, output);
      return;
    }

    // Handle static error test output specially. We don't want to show the raw
    // stdout if we can give the user the parsed expectations instead.
    if (testCase.testFile.isStaticErrorTest || hasCrashed || hasTimedOut) {
      super.describe(testCase, progress, output);
    } else {
      // Parse and sort the errors.
      var errorsByFile = <String?, List<AnalyzerError>>{};
      for (var error in AnalyzerError.parseStdout(decodeUtf8(stdout))) {
        errorsByFile.putIfAbsent(error.file, () => []).add(error);
      }

      var files = errorsByFile.keys.toList();
      files.sort();

      for (var file in files) {
        var path = Path(file!)
            .relativeTo(testCase.testFile.path.directoryPath)
            .toString();
        output.subsection("unexpected analysis errors in $path");

        var errors = errorsByFile[file]!;
        errors.sort();

        for (var error in errors) {
          var line = error.line.toString();
          var column = error.column.toString();
          var message = wordWrap(error.message.trim(), prefix: "  ");
          output.write("- Line $line, column $column: ${error.errorCode}");
          output.write("  $message");
          output.separator();
        }
      }
    }
  }

  /// Parses the JSON output of the analyzer.
  @override
  void _parseErrors() {
    var stdoutString = decodeUtf8(stdout);
    try {
      var errors = <StaticError>[];
      var warnings = <StaticError>[];
      parseErrors(stdoutString, errors, warnings);
      errors.forEach(addError);
      warnings.forEach(addWarning);
    } on FormatException {
      // It wasn't JSON. This can happen if analyzer instead prints:
      // "No dart files found at: ..."
      _invalidJsonStdout = stdoutString;
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

  @override
  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    if (exitCode != 0) return Expectation.fail;
    for (var line in decodeUtf8(stdout).split('\n')) {
      if (line.contains('No differences found')) return Expectation.pass;
      if (line.contains('Differences found')) return Expectation.fail;
    }
    return Expectation.fail;
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  @override
  Expectation realResult(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

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

  @override
  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

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
  @override
  Expectation realResult(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;
    if (hasSyntaxError) return Expectation.syntaxError;
    if (exitCode != 0) return Expectation.syntaxError;
    return Expectation.pass;
  }
}

class VMCommandOutput extends CommandOutput with _UnittestSuiteMessagesMixin {
  static const _dfeErrorExitCode = 252;
  static const _compileErrorExitCode = 254;
  static const _uncaughtExceptionExitCode = 255;
  static const _adbInfraFailureCodes = [10];
  static const _adbFailureExitCode = 3;
  static const _frontEndTestExitCode = 1;

  VMCommandOutput(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time, int pid)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, pid);

  @override
  Expectation result(TestCase testCase) {
    // `ffx test` isn't preserving exit codes.
    // TODO(38752): Plumb exit codes through something else?
    if (testCase.configuration.system == System.fuchsia) {
      if (utf8.decode(stdout).contains("completed with result: PASSED")) {
        return Expectation.pass;
      }
      return Expectation.fail;
    }

    // Handle crashes and timeouts first.
    if (exitCode == _dfeErrorExitCode) return Expectation.dartkCrash;
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

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

    return _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  @override
  Expectation realResult(TestCase testCase) {
    // `ffx test` isn't preserving exit codes.
    // TODO(38752): Plumb exit codes through something else?
    if (testCase.configuration.system == System.fuchsia) {
      if (utf8.decode(stdout).contains("completed with result: PASSED")) {
        return Expectation.pass;
      }
      return Expectation.fail;
    }

    // Handle crashes and timeouts first.
    if (exitCode == _dfeErrorExitCode) return Expectation.dartkCrash;
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    // The actual outcome depends on the exitCode.
    if (exitCode == _compileErrorExitCode) return Expectation.compileTimeError;
    if (exitCode == _uncaughtExceptionExitCode) return Expectation.runtimeError;
    if (exitCode == _frontEndTestExitCode &&
        testCase.displayName.startsWith('pkg/front_end/test/')) {
      return Expectation.runtimeError;
    }
    if (testCase.configuration.system == System.android &&
        _adbInfraFailureCodes.contains(exitCode)) {
      print('Android device failed to run test');
      print(command);
      print(decodeUtf8(stdout));
      print(decodeUtf8(stderr));
      io.exit(_adbFailureExitCode);
    }
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
  @override
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
    if (truncatedOutput) return Expectation.truncatedOutput;

    // Handle dart2js specific crash detection
    if (exitCode == _crashExitCode ||
        exitCode == VMCommandOutput._compileErrorExitCode ||
        exitCode == VMCommandOutput._uncaughtExceptionExitCode) {
      return Expectation.crash;
    }
    if (exitCode != 0) return Expectation.compileTimeError;
    return Expectation.pass;
  }

  @override
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
    if (truncatedOutput) return Expectation.truncatedOutput;

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

    return exitCode == 0 ? Expectation.pass : Expectation.compileTimeError;
  }
}

class Dart2jsCompilerCommandOutput extends CompilationCommandOutput
    with _StaticErrorOutput {
  static void parseErrors(String stdout, List<StaticError> errors) {
    _StaticErrorOutput._parseCfeErrors(
        ErrorSource.web, _errorRegexp, stdout, errors);
  }

  /// Matches the location and message of a dart2js error message, which looks
  /// like:
  ///
  ///     tests/language_2/some_test.dart:9:3:
  ///     Error: Some message.
  ///       BadThing();
  ///       ^
  ///
  /// The test runner only validates the main error message, and not the
  /// suggested fixes, so we only parse the first line.
  // TODO(rnystrom): Support validating context messages.
  static final _errorRegexp =
      RegExp(r"^([^:]+):(\d+):(\d+):\n(Error): (.*)$", multiLine: true);

  Dart2jsCompilerCommandOutput(super.command, super.exitCode, super.timedOut,
      super.stdout, super.stderr, super.time, super.compilationSkipped);

  @override
  void _parseErrors() {
    var errors = <StaticError>[];
    parseErrors(decodeUtf8(stdout), errors);
    errors.forEach(addError);
  }
}

class Dart2WasmCompilerCommandOutput extends CompilationCommandOutput
    with _StaticErrorOutput {
  static void parseErrors(String stdout, List<StaticError> errors) {
    _StaticErrorOutput._parseCfeErrors(
        ErrorSource.web, _errorRegexp, stdout, errors);
  }

  /// Matches the location and message of a dart2wasm error message, which looks
  /// like:
  ///
  ///     tests/language_2/some_test.dart:9:3: Error: Some message.
  ///       BadThing();
  ///       ^
  ///
  /// The test runner only validates the main error message, and not the
  /// suggested fixes, so we only parse the first line.
  // TODO(rnystrom): Support validating context messages.
  static final _errorRegexp =
      RegExp(r"^([^:]+):(\d+):(\d+): (Error): (.*)$", multiLine: true);

  Dart2WasmCompilerCommandOutput(super.command, super.exitCode, super.timedOut,
      super.stdout, super.stderr, super.time, super.compilationSkipped);

  @override
  void _parseErrors() {
    var errors = <StaticError>[];
    parseErrors(decodeUtf8(stdout), errors);
    errors.forEach(addError);
  }
}

class DevCompilerCommandOutput extends CommandOutput with _StaticErrorOutput {
  /// Matches the first line of a DDC error message. DDC prints errors to
  /// stdout that look like:
  ///
  ///     org-dartlang-app:/tests/language_2/some_test.dart:7:21: Error: Some message.
  ///     Try fixing the code to be less bad.
  ///       var _ = <int>[if (1) 2];
  ///                    ^
  ///
  /// The test runner only validates the main error message, and not the
  /// suggested fixes, so we only parse the first line.
  // TODO(rnystrom): Support validating context messages.
  static final _errorRegexp = RegExp(
      r"^org-dartlang-app:/([^:]+):(\d+):(\d+): (Error): (.*)$",
      multiLine: true);

  DevCompilerCommandOutput(
      super.command,
      super.exitCode,
      super.timedOut,
      super.stdout,
      super.stderr,
      super.time,
      super.compilationSkipped,
      super.pid);

  @override
  Expectation result(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
    }

    // Handle errors / missing errors
    if (testCase.hasCompileError) {
      return exitCode == 0
          ? Expectation.missingCompileTimeError
          : Expectation.pass;
    }

    return exitCode == 0 ? Expectation.pass : Expectation.compileTimeError;
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  @override
  Expectation realResult(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
    }

    if (exitCode != 0) return Expectation.compileTimeError;

    return Expectation.pass;
  }

  @override
  void _parseErrors() {
    var errors = <StaticError>[];
    _StaticErrorOutput._parseCfeErrors(
        ErrorSource.web, _errorRegexp, decodeUtf8(stdout), errors);
    errors.forEach(addError);
  }
}

class VMKernelCompilationCommandOutput extends CompilationCommandOutput {
  VMKernelCompilationCommandOutput(
      super.command,
      super.exitCode,
      super.timedOut,
      super.stdout,
      super.stderr,
      super.time,
      super.compilationSkipped);

  @override
  bool get canRunDependentCommands {
    // See [BatchRunnerProcess]: 0 means success, 1 means compile-time error.
    // TODO(asgerf): When the frontend supports it, continue running even if
    // there were compile-time errors. See kernel_sdk issue #18.
    return !hasCrashed && !hasTimedOut && exitCode == 0;
  }

  @override
  Expectation result(TestCase testCase) {
    // TODO(kustermann): Currently the batch mode runner (which can be found
    // in `test_runner.dart:BatchRunnerProcess`) does not really distinguish
    // between different kinds of failures and will mark a failed
    // compilation to just an exit code of "1".  So we treat all `exitCode ==
    // 1`s as compile-time errors as well.
    const batchModeCompileTimeErrorExit = 1;

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.dartkCrash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    // If the frontend had an uncaught exception, then we'll consider this a
    // crash.
    if (exitCode == VMCommandOutput._uncaughtExceptionExitCode) {
      return Expectation.dartkCrash;
    }

    // Multitests are handled specially.
    if (testCase.hasCompileError) {
      if (exitCode == VMCommandOutput._compileErrorExitCode ||
          exitCode == batchModeCompileTimeErrorExit) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }

    // The actual outcome depends on the exitCode.
    if (exitCode == VMCommandOutput._compileErrorExitCode ||
        exitCode == batchModeCompileTimeErrorExit) {
      return Expectation.compileTimeError;
    } else if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      return Expectation.fail;
    }

    return Expectation.pass;
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  @override
  Expectation realResult(TestCase testCase) {
    // TODO(kustermann): Currently the batch mode runner (which can be found
    // in `test_runner.dart:BatchRunnerProcess`) does not really distinguish
    // between different kinds of failures and will mark a failed
    // compilation to just an exit code of "1".  So we treat all `exitCode ==
    // 1`s as compile-time errors as well.
    const batchModeCompileTimeErrorExit = 1;

    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.dartkCrash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    // If the frontend had an uncaught exception, then we'll consider this a
    // crash.
    if (exitCode == VMCommandOutput._uncaughtExceptionExitCode) {
      return Expectation.dartkCrash;
    }

    // Multitests are handled specially.

    if (exitCode == VMCommandOutput._compileErrorExitCode ||
        exitCode == batchModeCompileTimeErrorExit) {
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
  @override
  bool get successful => canRunDependentCommands;
}

class JSCommandLineOutput extends CommandOutput
    with _UnittestSuiteMessagesMixin {
  JSCommandLineOutput(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, 0);

  @override
  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    if (testCase.hasRuntimeError) {
      if (exitCode != 0) return Expectation.pass;
      return Expectation.missingRuntimeError;
    }

    var outcome = exitCode == 0 ? Expectation.pass : Expectation.runtimeError;
    return _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  @override
  Expectation realResult(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    if (exitCode != 0) return Expectation.runtimeError;
    var output = decodeUtf8(stdout);
    if (_isAsyncTest(output) && !_isAsyncTestSuccessful(output)) {
      return Expectation.fail;
    }
    return Expectation.pass;
  }

  @override
  void describe(TestCase testCase, Progress progress, OutputWriter output) {
    super.describe(testCase, progress, output);
    var decodedOut = decodeUtf8(stdout)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    _deobfuscateAndWriteStack(decodedOut, output);
  }
}

class Dart2WasmCommandLineOutput extends CommandOutput
    with _UnittestSuiteMessagesMixin {
  Dart2WasmCommandLineOutput(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, 0);

  @override
  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    if (testCase.hasRuntimeError) {
      if (exitCode != 0) return Expectation.pass;
      return Expectation.missingRuntimeError;
    }

    var outcome = exitCode == 0 ? Expectation.pass : Expectation.runtimeError;
    return _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
  }

  /// Cloned code from member result(), with changes.
  /// Delete existing result() function and rename, when status files are gone.
  @override
  Expectation realResult(TestCase testCase) {
    // Handle crashes and timeouts first.
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

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

  @override
  Expectation result(TestCase testCase) => _result;

  @override
  Expectation realResult(TestCase testCase) => _result;

  @override
  bool get canRunDependentCommands => _result == Expectation.pass;

  @override
  bool get successful => _result == Expectation.pass;
}

class FastaCommandOutput extends CompilationCommandOutput
    with _StaticErrorOutput {
  static void parseErrors(
      String stdout, List<StaticError> errors, List<StaticError> warnings) {
    _StaticErrorOutput._parseCfeErrors(
        ErrorSource.cfe, _errorRegexp, stdout, errors, warnings);
  }

  /// Matches the first line of a Fasta error, warning, or context message.
  /// Fasta prints to stdout like:
  ///
  ///     tests/language_2/some_test.dart:7:21: Error: Some message.
  ///     Try fixing the code to be less bad.
  ///       var _ = <int>[if (1) 2];
  ///                    ^
  ///
  /// The test runner only validates the first line of the message, and not the
  /// suggested fixes.
  static final _errorRegexp = RegExp(
      r"^(?:([^:]+):(\d+):(\d+): )?(Context|Error|Warning): (.*)$",
      multiLine: true);

  FastaCommandOutput(super.command, super.exitCode, super.hasTimedOut,
      super.stdout, super.stderr, super.time, super.compilationSkipped);

  @override
  void _parseErrors() {
    var errors = <StaticError>[];
    var warnings = <StaticError>[];
    parseErrors(decodeUtf8(stdout), errors, warnings);
    errors.forEach(addError);
    warnings.forEach(addWarning);
  }
}

/// Mixin for outputs from a command that implement a Dart front end which
/// reports static errors.
mixin _StaticErrorOutput on CommandOutput {
  /// Parses compile errors reported by CFE using the given [regExp] and adds
  /// them to [errors] as coming from [errorSource].
  static void _parseCfeErrors(ErrorSource errorSource, RegExp regExp,
      String stdout, List<StaticError> errors,
      [List<StaticError>? warnings]) {
    StaticError? previousError;
    for (var match in regExp.allMatches(stdout)) {
      var line = _parseNullableInt(match.group(2));
      var column = _parseNullableInt(match.group(3));
      var severity = match.group(4);
      var message = match.group(5);

      if (line == null) {
        // No location information.
        if (severity == 'Context' && previousError != null) {
          // We can use the location information from the error message
          line = previousError.line;
          column = previousError.column;
        } else {
          // No good default location information, so disregard the error.
          // TODO(45558): we should do something smarter here.
          continue;
        }
      }
      // Column information should have been present or it should have been
      // filled in by the code above.
      assert(column != null);

      var error = StaticError(
          severity == "Context" ? ErrorSource.context : errorSource, message!,
          line: line, column: column!);

      if (severity == "Context") {
        // Attach context messages to the preceding error/warning.
        if (previousError == null) {
          DebugLogger.error("Got context message in CFE output before "
              "error to attach it to.");
        } else {
          previousError.contextMessages.add(error);
        }
      } else {
        if (severity == "Error") {
          errors.add(error);
        } else {
          warnings!.add(error);
        }
        previousError = error;
      }
    }
  }

  /// Same as `int.parse`, but allows nulls to simply pass through.
  static int? _parseNullableInt(String? s) {
    if (s == null) {
      return null;
    }
    return int.parse(s);
  }

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
    // Handle static error test output specially. We don't want to show the raw
    // stdout if we can give the user the parsed expectations instead.
    if (testCase.testFile.isStaticErrorTest &&
        !hasCrashed &&
        !hasTimedOut &&
        !hasNonUtf8 &&
        !truncatedOutput) {
      try {
        _validateExpectedErrors(testCase, output);
      } catch (_) {
        // In the event of a crash trying to compute errors, go ahead and give
        // the raw output.
        super.describe(testCase, progress, output);
        return;
      }

      // Always show the raw output when specifically requested.
      if (progress == Progress.verbose) {
        super.describe(testCase, progress, output);
      }
    } else {
      // Something strange happened, so show the raw output.
      super.describe(testCase, progress, output);
    }
  }

  @override
  Expectation result(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

    // If it's a static error test, validate the exact errors.
    if (testCase.testFile.isStaticErrorTest) {
      return _validateExpectedErrors(testCase);
    }

    return super.result(testCase);
  }

  @override
  Expectation realResult(TestCase testCase) {
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;
    if (truncatedOutput) return Expectation.truncatedOutput;

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
      [OutputWriter? writer]) {
    // Filter out errors that aren't for this configuration.
    var errorSource = const {
      Compiler.dart2analyzer: ErrorSource.analyzer,
      Compiler.dart2js: ErrorSource.web,
      Compiler.dart2wasm: ErrorSource.web,
      Compiler.ddc: ErrorSource.web,
      Compiler.fasta: ErrorSource.cfe
    }[testCase.configuration.compiler]!;

    var expected = testCase.testFile.expectedErrors
        .where((error) => error.source == errorSource);

    var validation = StaticError.validateExpectations(
      expected,
      [...errors, ...warnings],
    );
    if (validation == null) return Expectation.pass;

    writer?.subsection("static error failures");
    writer?.write(validation);

    return Expectation.missingCompileTimeError;
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

void _deobfuscateAndWriteStack(String stack, OutputWriter output) {
  try {
    var deobfuscatedStack = deobfuscateStackTrace(stack);
    if (deobfuscatedStack == stack) return;
    output.subsection('Deobfuscated error and stack');
    output.write(deobfuscatedStack);
  } catch (e, st) {
    output.subsection('Warning: not able to deobfuscate stack');
    output.writeAll(['input: $stack', 'error: $e', 'stack trace: $st']);
    return;
  }
}
