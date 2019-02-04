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
import 'test_runner.dart';
import 'utils.dart';

/// Controls how message strings are processed before being displayed.
class Formatter {
  /// Messages are left as-is.
  static const normal = const Formatter._();

  /// Messages are wrapped in ANSI escape codes to color them for display on a
  /// terminal.
  static const color = const _ColorFormatter();

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
      print('$_numCompleted out of $_numTests completed');
    }
    print("Tests running for ${(interval * timer.tick).inMinutes} minutes");
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
        print("/nMore than $maxIgnored tests were ignored due to flakes in");
        print("the test infrastructure. Notify whesse@google.com.");
        print("Output of the last ignored test was:");
        print(_buildFailureOutput(test));
        exit(1);
      }
    }
  }

  void allDone() {
    if (countIgnored > 0) {
      print("Ignored $countIgnored tests due to flaky infrastructure");
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
      var binName = lastCommand.executable;
      var binFile = new File(binName);
      var binBaseName = new Path(binName).filename;
      if (!archivedBinaries.containsKey(binName) && binFile.existsSync()) {
        var mode = test.configuration.mode.name;
        var arch = test.configuration.architecture.name;
        var archived = "binary.${mode}_${arch}_${binBaseName}";
        TestUtils.copyFile(new Path(binName), new Path(archived));
        // On Windows also copy PDB file for the binary.
        if (Platform.isWindows) {
          final pdbPath = new Path("$binName.pdb");
          if (new File(pdbPath.toNativePath()).existsSync()) {
            TestUtils.copyFile(pdbPath, new Path("$archived.pdb"));
          }
        }
        archivedBinaries[binName] = archived;
      }

      if (archivedBinaries.containsKey(binName)) {
        // We have found and copied the binary.
        RandomAccessFile unexpectedCrashesFile;
        try {
          unexpectedCrashesFile =
              new File('unexpected-crashes').openSync(mode: FileMode.append);
          unexpectedCrashesFile.writeStringSync(
              "${test.displayName},${pid},${archivedBinaries[binName]}\n");
        } catch (e) {
          print('Failed to add crash to unexpected-crashes list: ${e}');
        } finally {
          try {
            if (unexpectedCrashesFile != null) {
              unexpectedCrashesFile.closeSync();
            }
          } catch (e) {
            print('Failed to close unexpected-crashes file: ${e}');
          }
        }
      }
    }
  }
}

class SummaryPrinter extends EventListener {
  final bool jsonOnly;

  SummaryPrinter({bool jsonOnly})
      : jsonOnly = (jsonOnly == null) ? false : jsonOnly;

  void allTestsKnown() {
    if (jsonOnly) {
      print("JSON:");
      print(jsonEncode(summaryReport.values));
    } else {
      summaryReport.printReport();
    }
  }
}

class TimingPrinter extends EventListener {
  final _command2testCases = new Map<Command, List<TestCase>>();
  final _commandOutputs = new Set<CommandOutput>();
  DateTime _startTime;

  TimingPrinter(this._startTime);

  void done(TestCase testCase) {
    for (var commandOutput in testCase.commandOutputs.values) {
      var command = commandOutput.command;
      _commandOutputs.add(commandOutput);
      _command2testCases.putIfAbsent(command, () => <TestCase>[]);
      _command2testCases[command].add(testCase);
    }
  }

  void allDone() {
    Duration d = (new DateTime.now()).difference(_startTime);
    print('\n--- Total time: ${_timeString(d)} ---');
    var outputs = _commandOutputs.toList();
    outputs.sort((a, b) {
      return b.time.inMilliseconds - a.time.inMilliseconds;
    });
    for (int i = 0; i < 20 && i < outputs.length; i++) {
      var commandOutput = outputs[i];
      var command = commandOutput.command;
      var testCases = _command2testCases[command];

      var testCasesDescription = testCases.map((testCase) {
        return "${testCase.configurationString}/${testCase.displayName}";
      }).join(', ');

      print('${commandOutput.time} - '
          '${command.displayName} - '
          '$testCasesDescription');
    }
  }
}

class StatusFileUpdatePrinter extends EventListener {
  var statusToConfigs = new Map<String, List<String>>();
  var _failureSummary = <String>[];

  void done(TestCase test) {
    if (test.unexpectedOutput) {
      _printFailureOutput(test);
    }
  }

  void allDone() {
    _printFailureSummary();
  }

  void _printFailureOutput(TestCase test) {
    String status = '${test.displayName}: ${test.result}';
    List<String> configs =
        statusToConfigs.putIfAbsent(status, () => <String>[]);
    configs.add(test.configurationString);
    if (test.lastCommandOutput.hasTimedOut) {
      print('\n${test.displayName} timed out on ${test.configurationString}');
    }
  }

  String _extractRuntime(String configuration) {
    // Extract runtime from a configuration, for example,
    // 'none-vm-checked release_ia32'.
    List<String> runtime = configuration.split(' ')[0].split('-');
    return '${runtime[0]}-${runtime[1]}';
  }

  void _printFailureSummary() {
    var groupedStatuses = <String, List<String>>{};
    statusToConfigs.forEach((status, configs) {
      var runtimeToConfiguration = <String, List<String>>{};
      for (var config in configs) {
        var runtime = _extractRuntime(config);
        runtimeToConfiguration
            .putIfAbsent(runtime, () => <String>[])
            .add(config);
      }

      runtimeToConfiguration.forEach((runtime, runtimeConfigs) {
        runtimeConfigs.sort((a, b) => a.compareTo(b));
        var statuses = groupedStatuses.putIfAbsent(
            '$runtime: $runtimeConfigs', () => <String>[]);
        statuses.add(status);
      });
    });

    if (groupedStatuses.isEmpty) return;

    print('\n\nNecessary status file updates:');
    groupedStatuses.forEach((String config, List<String> statuses) {
      print('');
      print('$config:');
      statuses.sort((a, b) => a.compareTo(b));
      for (var status in statuses) {
        print('  $status');
      }
    });
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
      print('\n$_skippedCompilations compilations were skipped because '
          'the previous output was already up to date.\n');
    }
  }
}

class LineProgressIndicator extends EventListener {
  void done(TestCase test) {
    var status = 'pass';
    if (test.unexpectedOutput) {
      status = 'fail';
    }
    print('Done ${test.configurationString} ${test.displayName}: $status');
  }
}

class TestFailurePrinter extends EventListener {
  final bool _printSummary;
  final Formatter _formatter;
  final _failureSummary = <String>[];
  int _failedTests = 0;
  int _passedTests = 0;

  TestFailurePrinter(this._printSummary, [this._formatter = Formatter.normal]);

  void done(TestCase test) {
    if (test.unexpectedOutput) {
      _failedTests++;
      var lines = _buildFailureOutput(test, _formatter);
      for (var line in lines) {
        print(line);
      }
      print('');
      if (_printSummary) {
        _failureSummary.addAll(lines);
        _failureSummary.add('');
      }
    } else {
      _passedTests++;
    }
  }

  void allDone() {
    if (!_printSummary || _failureSummary.isEmpty) return;

    // Don't bother showing the summary if it's longer than the number of lines
    // of successful test output. The benefit of the summary is that it saves
    // you from scrolling past lots of passed tests to find the few failures.
    // If most of the output *is* failures, showing them *twice* just makes it
    // worse.
    if (_passedTests <= _failureSummary.length) return;

    print('\n=== Failure summary:\n');
    for (var line in _failureSummary) {
      print(line);
    }
    print('');
    print(_buildSummaryEnd(_formatter, _failedTests));
  }
}

class PassingStdoutPrinter extends EventListener {
  final Formatter _formatter;
  final _failureSummary = <String>[];

  PassingStdoutPrinter([this._formatter = Formatter.normal]);

  void done(TestCase test) {
    if (!test.unexpectedOutput) {
      var lines = <String>[];
      var output = new OutputWriter(_formatter, lines);
      for (final command in test.commands) {
        var commandOutput = test.commandOutputs[command];
        if (commandOutput == null) continue;

        commandOutput.describe(test.configuration.progress, output);
      }
      for (var line in lines) {
        print(line);
      }
    }
  }

  void allDone() {}
}

class ProgressIndicator extends EventListener {
  ProgressIndicator(this._startTime);

  static EventListener fromProgress(
      Progress progress, DateTime startTime, Formatter formatter) {
    switch (progress) {
      case Progress.compact:
        return new CompactProgressIndicator(startTime, formatter);
      case Progress.line:
        return new LineProgressIndicator();
      case Progress.verbose:
        return new VerboseProgressIndicator(startTime);
      case Progress.status:
        return new ProgressIndicator(startTime);
      case Progress.buildbot:
        return new BuildbotProgressIndicator(startTime);
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

  void _printDoneProgress(TestCase test) {}

  int _completedTests() => _passedTests + _failedTests;

  int _foundTests = 0;
  int _passedTests = 0;
  int _failedTests = 0;
  bool _allTestsKnown = false;
  DateTime _startTime;
}

abstract class CompactIndicator extends ProgressIndicator {
  CompactIndicator(DateTime startTime) : super(startTime);

  void allDone() {
    if (_failedTests > 0) {
      // We may have printed many failure logs, so reprint the summary data.
      _printProgress();
    }
    print('');
  }

  void _printDoneProgress(TestCase test) => _printProgress();

  void _printProgress();
}

class CompactProgressIndicator extends CompactIndicator {
  final Formatter _formatter;

  CompactProgressIndicator(DateTime startTime, this._formatter)
      : super(startTime);

  void _printProgress() {
    var percent = ((_completedTests() / _foundTests) * 100).toInt().toString();
    var progressPadded = (_allTestsKnown ? percent : '--').padLeft(3);
    var passedPadded = _passedTests.toString().padLeft(5);
    var failedPadded = _failedTests.toString().padLeft(5);
    var elapsed = (new DateTime.now()).difference(_startTime);
    var progressLine = '\r[${_timeString(elapsed)} | $progressPadded% | '
        '+${_formatter.passed(passedPadded)} | '
        '-${_formatter.failed(failedPadded)}]';
    stdout.write(progressLine);
  }
}

class VerboseProgressIndicator extends ProgressIndicator {
  VerboseProgressIndicator(DateTime startTime) : super(startTime);

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.unexpectedOutput) {
      status = 'fail';
    }
    print('Done ${test.configurationString} ${test.displayName}: $status');
  }
}

class BuildbotProgressIndicator extends ProgressIndicator {
  static String stepName;
  final _failureSummary = <String>[];

  BuildbotProgressIndicator(DateTime startTime) : super(startTime);

  void done(TestCase test) {
    super.done(test);
    if (test.unexpectedOutput) {
      _failureSummary.addAll(_buildFailureOutput(test));
    }
  }

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.unexpectedOutput) {
      status = 'fail';
    }
    var percent = ((_completedTests() / _foundTests) * 100).toInt().toString();
    print('Done ${test.configurationString} ${test.displayName}: $status');
    print('@@@STEP_CLEAR@@@');
    print('@@@STEP_TEXT@ $percent% +$_passedTests -$_failedTests @@@');
  }

  void allDone() {
    if (!_failureSummary.isEmpty) {
      print('@@@STEP_FAILURE@@@');
      if (stepName != null) {
        print('@@@BUILD_STEP $stepName failures@@@');
      }
      for (String line in _failureSummary) {
        print(line);
      }
      print('');
    }
    print(_buildSummaryEnd(Formatter.normal, _failedTests));
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

  OutputWriter(this._formatter, this._lines);

  void section(String name) {
    _pendingSection = name;
    _pendingSubsection = null;
  }

  void subsection(String name) {
    _pendingSubsection = name;
  }

  void write(String line) {
    _flushSection();
    _lines.add(line);
  }

  void writeAll(Iterable<String> lines) {
    if (lines.isEmpty) return;
    _flushSection();
    _lines.addAll(lines);
  }

  /// Writes the current section header.
  void _flushSection() {
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
  }
}

List<String> _buildFailureOutput(TestCase test,
    [Formatter formatter = Formatter.normal]) {
  var lines = <String>[];
  var output = new OutputWriter(formatter, lines);
  _writeFailureStatus(test, formatter, output);
  _writeFailureOutput(test, formatter, output);
  _writeFailureReproductionCommands(test, formatter, output);
  return lines;
}

List<String> _buildFailureLog(TestCase test) {
  final formatter = Formatter.normal;
  final lines = <String>[];
  final output = new OutputWriter(formatter, lines);
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
    commandOutput.describe(test.configuration.progress, output);
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

String _buildSummaryEnd(Formatter formatter, int failedTests) {
  if (failedTests == 0) {
    return formatter.passed('\n===\n=== All tests succeeded\n===\n');
  } else {
    var pluralSuffix = failedTests != 1 ? 's' : '';
    return formatter
        .failed('\n===\n=== ${failedTests} test$pluralSuffix failed\n===\n');
  }
}

/// Writes a results.json file with a line for each test.
/// Each line is a json map with the test name and result and expected result.
/// Also writes a run.json file with a json map containing the configuration
/// and the start time and duration of the run.
class ResultWriter extends EventListener {
  final TestConfiguration _configuration;
  final List<Map> _results = [];
  final List<Map> _logs = [];
  final String _outputDirectory;
  final Stopwatch _startStopwatch;
  final DateTime _startTime;

  ResultWriter(this._configuration, this._startTime, this._startStopwatch)
      : _outputDirectory = _configuration.outputDirectory;

  void allTestsKnown() {
    // Write an empty result log file, that will be overwritten if any tests
    // are actually run, when the allDone event handler is invoked.
    writeOutputFile([], TestUtils.resultsFileName);
    writeOutputFile([], TestUtils.logsFileName);
  }

  String newlineTerminated(Iterable<String> lines) =>
      lines.map((l) => l + '\n').join();

  void done(TestCase test) {
    if (_configuration != test.configuration) {
      throw new Exception("Two configurations in the same run. "
          "Cannot output results for multiple configurations.");
    }
    final name = test.displayName;
    final index = name.indexOf('/');
    final suite = name.substring(0, index);
    final testName = name.substring(index + 1);
    Duration time =
        test.commandOutputs.values.fold(Duration.zero, (d, o) => d + o.time);

    final record = {
      "name": name,
      "configuration": _configuration.configuration.name,
      "suite": suite,
      "test_name": testName,
      "time_ms": time.inMilliseconds,
      "result": test.realResult.toString(),
      "expected": test.realExpected.toString(),
      "matches": test.realResult.canBeOutcomeOf(test.realExpected)
    };
    _results.add(record);
    if (test.configuration.writeLogs && record['matches'] != true) {
      final log = {
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
    writeRunFile();
  }

  void writeOutputFile(List<Map> results, String fileName) {
    if (_outputDirectory == null) return;
    final path = Uri.directory(_outputDirectory).resolve(fileName);
    File.fromUri(path)
        .writeAsStringSync(newlineTerminated(results.map(jsonEncode)));
  }

  void writeRunFile() {
    _startStopwatch.stop();
    if (_outputDirectory == null) return;
    var suites = _configuration.selectors.keys.toList();
    var run = {
      "start_time": _startTime.millisecondsSinceEpoch ~/ 1000,
      "duration": _startStopwatch.elapsed.inSeconds,
      "configuration": _configuration.configuration.name,
      "suites": suites
    };
    final path = Uri.directory(_outputDirectory)
        .resolve(TestUtils.resultsInstanceFileName);
    File.fromUri(path).writeAsStringSync(jsonEncode(run) + '\n');
  }
}
