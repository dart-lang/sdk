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

/**
 * CommandOutput records the output of a completed command: the process's exit
 * code, the standard output and standard error, whether the process timed out,
 * and the time the process took to run.  It does not contain a pointer to the
 * [TestCase] this is the output of, so some functions require the test case
 * to be passed as an argument.
 */
abstract class CommandOutput {
  Command get command;

  Expectation result(TestCase testCase);

  bool get hasCrashed;

  bool get hasTimedOut;

  bool didFail(TestCase testCase);

  bool hasFailed(TestCase testCase);

  bool get canRunDependendCommands;

  bool get successful; // otherwise we might to retry running

  Duration get time;

  int get exitCode;

  int get pid;

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
  int pid;

  /**
   * A flag to indicate we have already printed a warning about ignoring the VM
   * crash, to limit the amount of output produced per test.
   */
  bool alreadyPrintedWarning = false;

  CommandOutputImpl(
      Command this.command,
      int this.exitCode,
      bool this.timedOut,
      List<int> this.stdout,
      List<int> this.stderr,
      Duration this.time,
      bool this.compilationSkipped,
      int this.pid) {
    diagnostics = [];
  }

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
      if (exitCode == 3 || exitCode == CRASHING_BROWSER_EXITCODE) {
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

  bool get hasNonUtf8 => exitCode == NON_UTF_FAKE_EXITCODE;

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

class ContentShellCommandOutputImpl extends CommandOutputImpl {
  // Although tests are reported as passing, content shell sometimes exits with
  // a nonzero exitcode which makes our dartium builders extremely falky.
  // See: http://dartbug.com/15139.
  // TODO(rnystrom): Is this still needed? The underlying bug is closed.
  static int WHITELISTED_CONTENTSHELL_EXITCODE = -1073740022;
  static bool isWindows = io.Platform.operatingSystem == 'windows';
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
    if (stderr.contains(MESSAGE_CANNOT_OPEN_DISPLAY) ||
        stderr.contains(MESSAGE_FAILED_TO_RUN_COMMAND)) {
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

  bool _infraFailure;

  ContentShellCommandOutputImpl(
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
    return super.canRunDependendCommands && !didFail(null);
  }

  bool get hasCrashed {
    return super.hasCrashed || _rendererCrashed;
  }

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
    bool hasContentType = false;
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
      return (!hasCrashed &&
          exitCode != 0 &&
          (!isWindows || exitCode != WHITELISTED_CONTENTSHELL_EXITCODE));
    }
    DebugLogger.warning("Couldn't find 'Content-Type: text/plain' in output. "
        "($command).");
    return true;
  }
}

class HTMLBrowserCommandOutputImpl extends ContentShellCommandOutputImpl {
  HTMLBrowserCommandOutputImpl(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped);

  bool didFail(TestCase testCase) {
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
  static const ALLOWED_TYPES = const [
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
        ALLOWED_TYPES.forEach((type) => messagesByType[type] = <String>[]);

        for (var entry in events) {
          validate("An entry must be a Map", entry is Map);

          var type = entry['type'];
          var value = entry['value'] as String;
          var timestamp = entry['timestamp'];

          validate("'type' of an entry must be a String", type is String);
          validate("'type' has to be in $ALLOWED_TYPES.",
              ALLOWED_TYPES.contains(type));
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

class BrowserCommandOutputImpl extends CommandOutputImpl
    with UnittestSuiteMessagesMixin {
  BrowserTestOutput _result;
  Expectation _rawOutcome;

  factory BrowserCommandOutputImpl(Command command, BrowserTestOutput result) {
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
    return new BrowserCommandOutputImpl._internal(
        command, result, outcome, encodeUtf8(stdout), encodeUtf8(stderr));
  }

  BrowserCommandOutputImpl._internal(Command command, BrowserTestOutput result,
      this._rawOutcome, List<int> stdout, List<int> stderr)
      : super(command, 0, result.didTimeout, stdout, stderr, result.duration,
            false, 0) {
    _result = result;
  }

  Expectation result(TestCase testCase) {
    // Handle timeouts first
    if (_result.didTimeout) {
      if (testCase.configuration.runtime == Runtime.ie11) {
        // TODO(28955): See http://dartbug.com/28955
        DebugLogger.warning("Timeout of ie11 on test ${testCase.displayName}");
        return Expectation.ignore;
      }
      return Expectation.timeout;
    }

    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Multitests are handled specially
    if (testCase.hasRuntimeError) {
      if (_rawOutcome == Expectation.runtimeError) return Expectation.pass;
      return Expectation.missingRuntimeError;
    }

    return _negateOutcomeIfNegativeTest(_rawOutcome, testCase.isNegative);
  }
}

class AnalysisCommandOutputImpl extends CommandOutputImpl {
  // An error line has 8 fields that look like:
  // ERROR|COMPILER|MISSING_SOURCE|file:/tmp/t.dart|15|1|24|Missing source.
  final int ERROR_LEVEL = 0;
  final int ERROR_TYPE = 1;
  final int FILENAME = 3;
  final int FORMATTED_ERROR = 7;

  AnalysisCommandOutputImpl(
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
    List<String> errors = [];
    List<String> warnings = [];
    parseAnalyzerOutput(errors, warnings);

    // Handle errors / missing errors
    if (testCase.expectCompileError) {
      if (errors.length > 0) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }
    if (errors.length > 0) {
      return Expectation.compileTimeError;
    }

    // Handle static warnings / missing static warnings
    if (testCase.hasStaticWarning) {
      if (warnings.length > 0) {
        return Expectation.pass;
      }
      return Expectation.missingStaticWarning;
    }
    if (warnings.length > 0) {
      return Expectation.staticWarning;
    }

    assert(errors.length == 0 && warnings.length == 0);
    assert(!testCase.hasCompileError && !testCase.hasStaticWarning);
    return Expectation.pass;
  }

  void parseAnalyzerOutput(List<String> outErrors, List<String> outWarnings) {
    // Parse a line delimited by the | character using \ as an escape character
    // like:  FOO|BAR|FOO\|BAR|FOO\\BAZ as 4 fields: FOO BAR FOO|BAR FOO\BAZ
    List<String> splitMachineError(String line) {
      StringBuffer field = new StringBuffer();
      List<String> result = [];
      bool escaped = false;
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
      if (line.length == 0) continue;
      List<String> fields = splitMachineError(line);
      // We only consider errors/warnings for files of interest.
      if (fields.length > FORMATTED_ERROR) {
        if (fields[ERROR_LEVEL] == 'ERROR') {
          outErrors.add(fields[FORMATTED_ERROR]);
        } else if (fields[ERROR_LEVEL] == 'WARNING') {
          outWarnings.add(fields[FORMATTED_ERROR]);
        }
        // OK to Skip error output that doesn't match the machine format
      }
    }
  }
}

class VmCommandOutputImpl extends CommandOutputImpl
    with UnittestSuiteMessagesMixin {
  static const DART_VM_EXITCODE_DFE_ERROR = 252;
  static const DART_VM_EXITCODE_COMPILE_TIME_ERROR = 254;
  static const DART_VM_EXITCODE_UNCAUGHT_EXCEPTION = 255;

  VmCommandOutputImpl(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time, int pid)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, pid);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (exitCode == DART_VM_EXITCODE_DFE_ERROR) return Expectation.dartkCrash;
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Multitests are handled specially
    if (testCase.expectCompileError) {
      if (exitCode == DART_VM_EXITCODE_COMPILE_TIME_ERROR) {
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

    // The actual outcome depends on the exitCode
    Expectation outcome;
    if (exitCode == DART_VM_EXITCODE_COMPILE_TIME_ERROR) {
      outcome = Expectation.compileTimeError;
    } else if (exitCode == DART_VM_EXITCODE_UNCAUGHT_EXCEPTION) {
      outcome = Expectation.runtimeError;
    } else if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      outcome = Expectation.fail;
    } else {
      outcome = Expectation.pass;
    }
    outcome = _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class CompilationCommandOutputImpl extends CommandOutputImpl {
  static const DART2JS_EXITCODE_CRASH = 253;

  CompilationCommandOutputImpl(
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
      bool isWindows = io.Platform.operatingSystem == 'windows';
      bool isBrowserTestCase =
          testCase.commands.any((command) => command is BrowserTestCommand);
      // TODO(26060) Dart2js batch mode hangs on Windows under heavy load.
      return (isWindows && isBrowserTestCase)
          ? Expectation.ignore
          : Expectation.timeout;
    }
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    // Handle dart2js specific crash detection
    if (exitCode == DART2JS_EXITCODE_CRASH ||
        exitCode == VmCommandOutputImpl.DART_VM_EXITCODE_COMPILE_TIME_ERROR ||
        exitCode == VmCommandOutputImpl.DART_VM_EXITCODE_UNCAUGHT_EXCEPTION) {
      return Expectation.crash;
    }

    // Multitests are handled specially
    if (testCase.expectCompileError) {
      // Nonzero exit code of the compiler means compilation failed
      // TODO(kustermann): Do we have a special exit code in that case???
      if (exitCode != 0) {
        return Expectation.pass;
      }
      return Expectation.missingCompileTimeError;
    }

    // TODO(kustermann): This is a hack, remove it
    if (testCase.hasRuntimeError && testCase.commands.length > 1) {
      // We expected to run the test, but we got an compile time error.
      // If the compilation succeeded, we wouldn't be in here!
      assert(exitCode != 0);
      return Expectation.compileTimeError;
    }

    Expectation outcome =
        exitCode == 0 ? Expectation.pass : Expectation.compileTimeError;
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class KernelCompilationCommandOutputImpl extends CompilationCommandOutputImpl {
  KernelCompilationCommandOutputImpl(
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
    //   there were compile-time errors. See kernel_sdk issue #18.
    return !hasCrashed && !timedOut && exitCode == 0;
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

  // If the compiler was able to produce a Kernel IR file we want to run the
  // result on the Dart VM.  We therefore mark the [KernelCompilationCommand] as
  // successful.
  // => This ensures we test that the DartVM produces correct CompileTime errors
  //    as it is supposed to for our test suites.
  bool get successful => canRunDependendCommands;
}

class JsCommandlineOutputImpl extends CommandOutputImpl
    with UnittestSuiteMessagesMixin {
  JsCommandlineOutputImpl(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, 0);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
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

class PubCommandOutputImpl extends CommandOutputImpl {
  PubCommandOutputImpl(PubCommand command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, 0);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.crash;
    if (hasTimedOut) return Expectation.timeout;
    if (hasNonUtf8) return Expectation.nonUtf8Error;

    if (exitCode == 0) {
      return Expectation.pass;
    } else if ((command as PubCommand).command == 'get') {
      return Expectation.pubGetError;
    } else {
      return Expectation.fail;
    }
  }
}

class ScriptCommandOutputImpl extends CommandOutputImpl {
  final Expectation _result;

  ScriptCommandOutputImpl(ScriptCommand command, this._result,
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
    return new ContentShellCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is BrowserTestCommand) {
    return new HTMLBrowserCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is AnalysisCommand) {
    return new AnalysisCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is VmCommand) {
    return new VmCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is KernelCompilationCommand) {
    return new KernelCompilationCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is AdbPrecompilationCommand) {
    return new VmCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is CompilationCommand) {
    if (command.displayName == 'precompiler' ||
        command.displayName == 'app_jit') {
      return new VmCommandOutputImpl(
          command, exitCode, timedOut, stdout, stderr, time, pid);
    }
    return new CompilationCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is JSCommandlineCommand) {
    return new JsCommandlineOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time);
  } else if (command is PubCommand) {
    return new PubCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time);
  }

  return new CommandOutputImpl(command, exitCode, timedOut, stdout, stderr,
      time, compilationSkipped, pid);
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
