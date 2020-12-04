// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:status_file/expectation.dart";

import 'command.dart';
import 'command_output.dart';
import 'configuration.dart';
import 'path.dart';
import 'summary_report.dart';
import 'terminal.dart';
import 'test_case.dart';
import 'utils.dart';

/// Controls how message strings are processed before being displayed.
class Formatter {
  /// Messages are left as-is.
  static const normal = Formatter._();

  /// Messages are wrapped in ANSI escape codes to color them for display on a
  /// terminal.
  static const color = _ColorFormatter();

  const Formatter._();

  /// Formats a success message.
  String passed(String message) => message;

  /// Formats a failure message.
  String failed(String message) => message;

  /// Formats a section header.
  String section(String message) => message;
}

class _ColorFormatter extends Formatter {
  static const _gray = "1;30";
  static const _green = "32";
  static const _red = "31";
  static const _escape = '\u001b';

  const _ColorFormatter() : super._();

  String passed(String message) => _color(message, _green);
  String failed(String message) => _color(message, _red);
  String section(String message) => _color(message, _gray);

  static String _color(String message, String color) =>
      "$_escape[${color}m$message$_escape[0m";
}

class EventListener {
  void testAdded() {}
  void done(TestCase test) {}
  void allTestsKnown() {}
  void allDone() {}
}

class ExitCodeSetter extends EventListener {
  void done(TestCase test) {
    if (test.unexpectedOutput) {
      exitCode = 1;
    }
  }
}

class TimedProgressPrinter extends EventListener {
  static const interval = Duration(minutes: 5);
  int _numTests = 0;
  int _numCompleted = 0;
  bool _allKnown = false;
  Timer _timer;

  TimedProgressPrinter() {
    _timer = Timer.periodic(interval, callback);
  }

  void callback(Timer timer) {
    if (_allKnown) {
      Terminal.print('$_numCompleted out of $_numTests completed');
    }
    Terminal.print(
        "Tests running for ${(interval * timer.tick).inMinutes} minutes");
  }

  void testAdded() => _numTests++;

  void done(TestCase test) => _numCompleted++;

  void allTestsKnown() => _allKnown = true;

  void allDone() => _timer.cancel();
}

class IgnoredTestMonitor extends EventListener {
  static final int maxIgnored = 10;

  int countIgnored = 0;

  void done(TestCase test) {
    if (test.lastCommandOutput.result(test) == Expectation.ignore) {
      countIgnored++;
      if (countIgnored > maxIgnored) {
        Terminal.print(
            "\nMore than $maxIgnored tests were ignored due to flakes in");
        Terminal.print("the test infrastructure. Notify dart-engprod@.");
        Terminal.print("Output of the last ignored test was:");
        Terminal.print(_buildFailureOutput(test));
        exit(1);
      }
    }
  }

  void allDone() {
    if (countIgnored > 0) {
      Terminal.print("Ignored $countIgnored tests due to flaky infrastructure");
    }
  }
}

class UnexpectedCrashLogger extends EventListener {
  final archivedBinaries = <String, String>{};

  void done(TestCase test) {
    if (test.unexpectedOutput &&
        test.result == Expectation.crash &&
        test.lastCommandExecuted is ProcessCommand &&
        test.lastCommandOutput.hasCoreDump) {
      final mode = test.configuration.mode.name;
      final arch = test.configuration.architecture.name;

      var pid = "${test.lastCommandOutput.pid}";
      var lastCommand = test.lastCommandExecuted as ProcessCommand;

      // We might have a coredump for the process. This coredump will be
      // archived by CoreDumpArchiver (see tools/utils.py).
      //
      // For debugging purposes we need to archive the crashed binary as well.
      //
      // To simplify the archiving code we simply copy binaries into current
      // folder next to core dumps and name them
      // `binary.${mode}_${arch}_${binary_name}`.
      final binName = lastCommand.executable;
      final binFile = File(binName);
      final binBaseName = Path(binName).filename;
      if (!archivedBinaries.containsKey(binName) && binFile.existsSync()) {
        final archived = "binary.${mode}_${arch}_$binBaseName";
        TestUtils.copyFile(Path(binName), Path(archived));
        // On Windows also copy PDB file for the binary.
        if (Platform.isWindows) {
          final pdbPath = Path("$binName.pdb");
          if (File(pdbPath.toNativePath()).existsSync()) {
            TestUtils.copyFile(pdbPath, Path("$archived.pdb"));
          }
        }
        archivedBinaries[binName] = archived;
      }

      final kernelServiceBaseName = 'kernel-service.dart.snapshot';
      final kernelService =
          File('${binFile.parent.path}/$kernelServiceBaseName');
      if (!archivedBinaries.containsKey(kernelService) &&
          kernelService.existsSync()) {
        final archived = "binary.${mode}_${arch}_$kernelServiceBaseName";
        TestUtils.copyFile(Path(kernelService.path), Path(archived));
        archivedBinaries[kernelServiceBaseName] = archived;
      }

      final binaryPath = archivedBinaries[binName];
      if (binaryPath != null) {
        final binaries = <String>[binaryPath];
        final kernelServiceBinaryPath = archivedBinaries[kernelServiceBaseName];
        if (kernelServiceBinaryPath != null) {
          binaries.add(kernelServiceBinaryPath);
        }

        // We have found and copied the binary.
        RandomAccessFile unexpectedCrashesFile;
        try {
          unexpectedCrashesFile =
              File('unexpected-crashes').openSync(mode: FileMode.append);
          unexpectedCrashesFile.writeStringSync(
              "${test.displayName},$pid,${binaries.join(',')}\n");
        } catch (e) {
          Terminal.print('Failed to add crash to unexpected-crashes list: $e');
        } finally {
          try {
            if (unexpectedCrashesFile != null) {
              unexpectedCrashesFile.closeSync();
            }
          } catch (e) {
            Terminal.print('Failed to close unexpected-crashes file: $e');
          }
        }
      }
    }
  }
}

class SummaryPrinter extends EventListener {
  final bool jsonOnly;

  SummaryPrinter({bool jsonOnly}) : jsonOnly = jsonOnly ?? false;

  void allTestsKnown() {
    if (jsonOnly) {
      Terminal.print("JSON:");
      Terminal.print(jsonEncode(summaryReport.values));
    } else {
      summaryReport.printReport();
    }
  }
}

class TimingPrinter extends EventListener {
  final _commandToTestCases = <Command, List<TestCase>>{};
  final _commandOutputs = <CommandOutput>{};
  final DateTime _startTime;

  TimingPrinter(this._startTime);

  void done(TestCase test) {
    for (var commandOutput in test.commandOutputs.values) {
      var command = commandOutput.command;
      _commandOutputs.add(commandOutput);
      _commandToTestCases.putIfAbsent(command, () => <TestCase>[]);
      _commandToTestCases[command].add(test);
    }
  }

  void allDone() {
    var d = DateTime.now().difference(_startTime);
    Terminal.print('\n--- Total time: ${_timeString(d)} ---');
    var outputs = _commandOutputs.toList();
    outputs.sort((a, b) {
      return b.time.inMilliseconds - a.time.inMilliseconds;
    });
    for (var i = 0; i < 20 && i < outputs.length; i++) {
      var commandOutput = outputs[i];
      var command = commandOutput.command;
      var testCases = _commandToTestCases[command];

      var testCasesDescription = testCases.map((testCase) {
        return "${testCase.configurationString}/${testCase.displayName}";
      }).join(', ');

      Terminal.print('${commandOutput.time} - '
          '${command.displayName} - '
          '$testCasesDescription');
    }
  }
}

class SkippedCompilationsPrinter extends EventListener {
  int _skippedCompilations = 0;

  void done(TestCase test) {
    for (var commandOutput in test.commandOutputs.values) {
      if (commandOutput.compilationSkipped) _skippedCompilations++;
    }
  }

  void allDone() {
    if (_skippedCompilations > 0) {
      Terminal.print(
          '\n$_skippedCompilations compilations were skipped because '
          'the previous output was already up to date.\n');
    }
  }
}

class TestFailurePrinter extends EventListener {
  final Formatter _formatter;

  TestFailurePrinter([this._formatter = Formatter.normal]);

  void done(TestCase test) {
    if (!test.unexpectedOutput) return;
    for (var line in _buildFailureOutput(test, _formatter)) {
      Terminal.print(line);
    }
  }
}

/// Prints a one-line summary of passed and failed tests.
class ResultCountPrinter extends EventListener {
  final Formatter _formatter;
  int _failedTests = 0;
  int _passedTests = 0;

  ResultCountPrinter(this._formatter);

  void done(TestCase test) {
    if (test.unexpectedOutput) {
      _failedTests++;
    } else {
      _passedTests++;
    }
  }

  void allDone() {
    var suffix = _passedTests != 1 ? 's' : '';
    var passed =
        '${_formatter.passed(_passedTests.toString())} test$suffix passed';

    String summary;
    if (_failedTests == 0) {
      summary = 'All $passed';
    } else {
      summary = '$passed, ${_formatter.failed(_failedTests.toString())} failed';
    }

    var marker = _formatter.section('===');
    Terminal.print('\n$marker $summary $marker');
  }
}

/// Prints a list of the tests that failed.
class FailedTestsPrinter extends EventListener {
  final List<TestCase> _failedTests = [];

  FailedTestsPrinter();

  void done(TestCase test) {
    if (test.unexpectedOutput) {
      _failedTests.add(test);
    }
  }

  void allDone() {
    if (_failedTests.isEmpty) return;

    Terminal.print('');
    Terminal.print('=== Failed tests ===');
    for (var test in _failedTests) {
      var result = test.realResult.toString();
      if (test.realExpected != Expectation.pass) {
        result += ' (expected ${test.realExpected})';
      }

      Terminal.print('${test.displayName}: $result');
    }
  }
}

class PassingStdoutPrinter extends EventListener {
  final Formatter _formatter;

  PassingStdoutPrinter([this._formatter = Formatter.normal]);

  void done(TestCase test) {
    if (!test.unexpectedOutput) {
      var lines = <String>[];
      var output = OutputWriter(_formatter, lines);
      for (final command in test.commands) {
        var commandOutput = test.commandOutputs[command];
        if (commandOutput == null) continue;

        commandOutput.describe(test, test.configuration.progress, output);
      }
      for (var line in lines) {
        Terminal.print(line);
      }
    }
  }

  void allDone() {}
}

abstract class ProgressIndicator extends EventListener {
  final DateTime _startTime;
  int _foundTests = 0;
  int _passedTests = 0;
  int _failedTests = 0;
  bool _allTestsKnown = false;

  ProgressIndicator(this._startTime);

  static EventListener fromProgress(
      Progress progress, DateTime startTime, Formatter formatter) {
    switch (progress) {
      case Progress.compact:
        return CompactProgressIndicator(startTime, formatter);
      case Progress.line:
      case Progress.verbose:
        return LineProgressIndicator(startTime);
      case Progress.status:
        return null;
      case Progress.buildbot:
        return BuildbotProgressIndicator(startTime);
    }

    throw "unreachable";
  }

  void testAdded() {
    _foundTests++;
  }

  void done(TestCase test) {
    if (test.unexpectedOutput) {
      _failedTests++;
    } else {
      _passedTests++;
    }
    _printDoneProgress(test);
  }

  void allTestsKnown() {
    _allTestsKnown = true;
  }

  void _printDoneProgress(TestCase test);

  int get _completedTests => _passedTests + _failedTests;
}

abstract class CompactIndicator extends ProgressIndicator {
  CompactIndicator(DateTime startTime) : super(startTime);
}

class CompactProgressIndicator extends CompactIndicator {
  final Formatter _formatter;

  CompactProgressIndicator(DateTime startTime, this._formatter)
      : super(startTime);

  void _printDoneProgress(TestCase test) {
    var percent = ((_completedTests / _foundTests) * 100).toInt().toString();
    var progressPadded = (_allTestsKnown ? percent : '--').padLeft(3);
    var passedPadded = _passedTests.toString().padLeft(5);
    var failedPadded = _failedTests.toString().padLeft(5);
    var elapsed = DateTime.now().difference(_startTime);
    var progressLine = '\r[${_timeString(elapsed)} | $progressPadded% | '
        '+${_formatter.passed(passedPadded)} | '
        '-${_formatter.failed(failedPadded)}]';
    Terminal.writeLine(progressLine);
  }

  void allDone() {
    Terminal.finishLine();
  }
}

class LineProgressIndicator extends ProgressIndicator {
  LineProgressIndicator(DateTime startTime) : super(startTime);

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.unexpectedOutput) {
      status = 'fail';
    }
    Terminal.print(
        'Done ${test.configurationString} ${test.displayName}: $status');
  }
}

class BuildbotProgressIndicator extends ProgressIndicator {
  static String stepName;

  BuildbotProgressIndicator(DateTime startTime) : super(startTime);

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.unexpectedOutput) {
      status = 'fail';
    }
    var percent = ((_completedTests / _foundTests) * 100).toInt().toString();
    Terminal.print(
        'Done ${test.configurationString} ${test.displayName}: $status');
    Terminal.print('@@@STEP_CLEAR@@@');
    Terminal.print('@@@STEP_TEXT@ $percent% +$_passedTests -$_failedTests @@@');
  }

  void allDone() {
    if (_failedTests == 0) return;
    Terminal.print('@@@STEP_FAILURE@@@');
    if (stepName != null) Terminal.print('@@@BUILD_STEP $stepName failures@@@');
  }
}

String _timeString(Duration duration) {
  var min = duration.inMinutes;
  var sec = duration.inSeconds % 60;
  return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

/// Builds and formats the failure output for a failed test.
class OutputWriter {
  final Formatter _formatter;
  final List<String> _lines;
  String _pendingSection;
  String _pendingSubsection;
  bool _pendingLine = false;

  OutputWriter(this._formatter, this._lines);

  void section(String name) {
    _pendingSection = name;
    _pendingSubsection = null;
    _pendingLine = false;
  }

  void subsection(String name) {
    _pendingSubsection = name;
    _pendingLine = false;
  }

  void write(String line) {
    _writePending();
    _lines.add(line);
  }

  void writeAll(Iterable<String> lines) {
    if (lines.isEmpty) return;
    _writePending();
    _lines.addAll(lines);
  }

  /// Writes a blank line that separates lines of output.
  ///
  /// If no output is written after this before the next section, subsection,
  /// or end out output, doesn't write the line.
  void separator() {
    _pendingLine = true;
  }

  /// Writes the current section header.
  void _writePending() {
    if (_pendingSection != null) {
      if (_lines.isNotEmpty) _lines.add("");
      _lines.add(_formatter.section("--- $_pendingSection:"));
      _pendingSection = null;
    }

    if (_pendingSubsection != null) {
      _lines.add("");
      _lines.add(_formatter.section("$_pendingSubsection:"));
      _pendingSubsection = null;
    }

    if (_pendingLine) {
      _lines.add("");
      _pendingLine = false;
    }
  }
}

List<String> _buildFailureOutput(TestCase test,
    [Formatter formatter = Formatter.normal]) {
  var lines = <String>[];
  var output = OutputWriter(formatter, lines);
  _writeFailureStatus(test, formatter, output);
  _writeFailureOutput(test, formatter, output);
  _writeFailureReproductionCommands(test, formatter, output);
  return lines;
}

List<String> _buildFailureLog(TestCase test) {
  final formatter = Formatter.normal;
  final lines = <String>[];
  final output = OutputWriter(formatter, lines);
  _writeFailureOutput(test, formatter, output);
  _writeFailureReproductionCommands(test, formatter, output);
  return lines;
}

void _writeFailureStatus(
    TestCase test, Formatter formatter, OutputWriter output) {
  output.write('');
  output.write(formatter
      .failed('FAILED: ${test.configurationString} ${test.displayName}'));

  output.write('Expected: ${test.expectedOutcomes.join(" ")}');
  output.write('Actual: ${test.result}');

  final ranAllCommands = test.commandOutputs.length == test.commands.length;
  if (!test.lastCommandOutput.hasTimedOut) {
    if (!ranAllCommands && !test.hasCompileError) {
      output.write('Unexpected compile error.');
    } else {
      if (test.hasCompileError) {
        output.write('Missing expected compile error.');
      }
      if (test.hasRuntimeError) {
        output.write('Missing expected runtime error.');
      }
    }
  }
}

void _writeFailureOutput(
    TestCase test, Formatter formatter, OutputWriter output) {
  for (var i = 0; i < test.commands.length; i++) {
    var command = test.commands[i];
    var commandOutput = test.commandOutputs[command];
    if (commandOutput == null) continue;

    var time = niceTime(commandOutput.time);
    output.section('Command "${command.displayName}" (took $time)');
    output.write(command.toString());
    commandOutput.describe(test, test.configuration.progress, output);
  }
}

void _writeFailureReproductionCommands(
    TestCase test, Formatter formatter, OutputWriter output) {
  final ranAllCommands = test.commandOutputs.length == test.commands.length;
  if (test.configuration.runtime.isBrowser && ranAllCommands) {
    // Additional command for rerunning the steps locally after the fact.
    output.section('To debug locally, run');
    output.write(test.configuration.servers.commandLine);
  }

  output.section('Re-run this test');
  List<String> arguments;
  if (Platform.isFuchsia) {
    arguments = [Platform.executable, Platform.script.path];
  } else {
    arguments = ['python', 'tools/test.py'];
  }
  arguments.addAll(test.configuration.reproducingArguments);
  arguments.add(test.displayName);

  output.write(arguments.map(escapeCommandLineArgument).join(' '));
}

/// Writes a results.json file with a line for each test.
/// Each line is a json map with the test name and result and expected result.
class ResultWriter extends EventListener {
  final List<Map> _results = [];
  final List<Map> _logs = [];
  final String _outputDirectory;

  ResultWriter(this._outputDirectory);

  void allTestsKnown() {
    // Write an empty result log file, that will be overwritten if any tests
    // are actually run, when the allDone event handler is invoked.
    writeOutputFile([], TestUtils.resultsFileName);
    writeOutputFile([], TestUtils.logsFileName);
  }

  String newlineTerminated(Iterable<String> lines) =>
      lines.map((l) => l + '\n').join();

  void done(TestCase test) {
    var name = test.displayName;
    var index = name.indexOf('/');
    var suite = name.substring(0, index);
    var testName = name.substring(index + 1);
    var time =
        test.commandOutputs.values.fold(Duration.zero, (d, o) => d + o.time);

    var record = {
      "name": name,
      "configuration": test.configuration.configuration.name,
      "suite": suite,
      "test_name": testName,
      "time_ms": time.inMilliseconds,
      "result": test.realResult.toString(),
      "expected": test.realExpected.toString(),
      "matches": test.realResult.canBeOutcomeOf(test.realExpected)
    };
    _results.add(record);
    if (test.configuration.writeLogs && record['matches'] != true) {
      var log = {
        'name': name,
        'configuration': record['configuration'],
        'result': record['result'],
        'log': newlineTerminated(_buildFailureLog(test))
      };
      _logs.add(log);
    }
  }

  void allDone() {
    writeOutputFile(_results, TestUtils.resultsFileName);
    writeOutputFile(_logs, TestUtils.logsFileName);
  }

  void writeOutputFile(List<Map> results, String fileName) {
    if (_outputDirectory == null) return;
    var path = Uri.directory(_outputDirectory).resolve(fileName);
    File.fromUri(path)
        .writeAsStringSync(newlineTerminated(results.map(jsonEncode)));
  }
}
