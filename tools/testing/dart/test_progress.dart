// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_progress;

import "dart:async";
import "dart:io";
import "dart:io" as io;
import "dart:convert" show JSON;
import "path.dart";
import "status_file_parser.dart";
import "test_runner.dart";
import "test_suite.dart";
import "utils.dart";

String _pad(String s, int length) {
  StringBuffer buffer = new StringBuffer();
  for (int i = s.length; i < length; i++) {
    buffer.write(' ');
  }
  buffer.write(s);
  return buffer.toString();
}

String _padTime(int time) {
  if (time == 0) {
    return '00';
  } else if (time < 10) {
    return '0$time';
  } else {
    return '$time';
  }
}

String _timeString(Duration d) {
  var min = d.inMinutes;
  var sec = d.inSeconds % 60;
  return '${_padTime(min)}:${_padTime(sec)}';
}

class Formatter {
  const Formatter();
  String passed(msg) => msg;
  String failed(msg) => msg;
}

class ColorFormatter extends Formatter {
  static int BOLD = 1;
  static int GREEN = 32;
  static int RED = 31;
  static int NONE = 0;
  static String ESCAPE = decodeUtf8([27]);

  String passed(String msg) => _color(msg, GREEN);
  String failed(String msg) => _color(msg, RED);

  static String _color(String msg, int color) {
    return "$ESCAPE[${color}m$msg$ESCAPE[0m";
  }
}


List<String> _buildFailureOutput(TestCase test,
                                 [Formatter formatter = const Formatter()]) {

  List<String> getLinesWithoutCarriageReturn(List<int> output) {
    return decodeUtf8(output).replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n').split('\n');
  }

  List<String> output = new List<String>();
  output.add('');
  output.add(formatter.failed('FAILED: ${test.configurationString}'
                              ' ${test.displayName}'));
  StringBuffer expected = new StringBuffer();
  expected.write('Expected: ');
  for (var expectation in test.expectedOutcomes) {
    expected.write('$expectation ');
  }
  output.add(expected.toString());
  output.add('Actual: ${test.result}');
  if (!test.lastCommandOutput.hasTimedOut) {
    if (test.commandOutputs.length != test.commands.length
        && !test.expectCompileError) {
      output.add('Unexpected compile-time error.');
    } else {
      if (test.expectCompileError) {
        output.add('Compile-time error expected.');
      }
      if (test.hasRuntimeError) {
        output.add('Runtime error expected.');
      }
      if (test.configuration['checked'] && test.isNegativeIfChecked) {
        output.add('Dynamic type error expected.');
      }
    }
  }
  for (var i = 0; i < test.commands.length; i++) {
    var command = test.commands[i];
    var commandOutput = test.commandOutputs[command];
    if (commandOutput != null) {
      output.add("CommandOutput[${command.displayName}]:");
      if (!commandOutput.diagnostics.isEmpty) {
        String prefix = 'diagnostics:';
        for (var s in commandOutput.diagnostics) {
          output.add('$prefix ${s}');
          prefix = '   ';
        }
      }
      if (!commandOutput.stdout.isEmpty) {
        output.add('');
        output.add('stdout:');
        output.addAll(getLinesWithoutCarriageReturn(commandOutput.stdout));
      }
      if (!commandOutput.stderr.isEmpty) {
        output.add('');
        output.add('stderr:');
        output.addAll(getLinesWithoutCarriageReturn(commandOutput.stderr));
      }
    }
  }
  if (test is BrowserTestCase) {
    // Additional command for rerunning the steps locally after the fact.
    var command =
      test.configuration["_servers_"].httpServerCommandline();
    output.add('');
    output.add('To retest, run:  $command');
  }
  for (var i = 0; i < test.commands.length; i++) {
    var command = test.commands[i];
    var commandOutput = test.commandOutputs[command];
    output.add('');
    output.add('Command[${command.displayName}]: $command');
    if (commandOutput != null) {
      output.add('Took ${commandOutput.time}');
    } else {
      output.add('Did not run');
    }
  }

  var arguments = ['python', 'tools/test.py'];
  arguments.addAll(test.configuration['_reproducing_arguments_']);
  arguments.add(test.displayName);
  var testPyCommandline = arguments.map(escapeCommandLineArgument).join(' ');

  output.add('');
  output.add('Short reproduction command (experimental):');
  output.add("    $testPyCommandline");
  return output;
}

String _buildSummaryEnd(int failedTests) {
    if (failedTests == 0) {
      return '\n===\n=== All tests succeeded\n===\n';
    } else {
      var pluralSuffix = failedTests != 1 ? 's' : '';
      return '\n===\n=== ${failedTests} test$pluralSuffix failed\n===\n';
    }
}


class EventListener {
  void testAdded() { }
  void done(TestCase test) { }
  void allTestsKnown() { }
  void allDone() { }
}

class ExitCodeSetter extends EventListener {
  void done(TestCase test) {
    if (test.unexpectedOutput) {
      io.exitCode = 1;
    }
  }
}

class FlakyLogWriter extends EventListener {
  void done(TestCase test) {
    if (test.isFlaky && test.result != Expectation.PASS) {
      var buf = new StringBuffer();
      for (var l in _buildFailureOutput(test)) {
        buf.write("$l\n");
      }
      _appendToFlakyFile(buf.toString());
    }
  }

  void _appendToFlakyFile(String msg) {
    var file = new File(TestUtils.flakyFileName());
    var fd = file.openSync(mode: FileMode.APPEND);
    fd.writeStringSync(msg);
    fd.closeSync();
  }
}

class TestOutcomeLogWriter extends EventListener {
  /*
   * The ".test-outcome.log" file contains one line for every executed test.
   * Such a line is an encoded JSON data structure of the following form:
   * The durations are double values in milliseconds.
   *
   *  {
   *     name: 'co19/LibTest/math/x',
   *     configuration: {
   *       mode : 'release',
   *       compiler : 'dart2js',
   *       ....
   *     },
   *     test_result: {
   *       outcome: 'RuntimeError',
   *       expected_outcomes: ['Pass', 'Fail'],
   *       duration: 2600.64,
   *       command_results: [
   *         {
   *           name: 'dart2js',
   *           duration: 2400.44,
   *         },
   *         {
   *           name: 'ff',
   *           duration: 200.2,
   *         },
   *       ],
   *     }
   *  },
   */

  static final INTERESTED_CONFIGURATION_PARAMETERS =
      ['mode', 'arch', 'compiler', 'runtime', 'checked', 'host_checked',
       'minified', 'csp', 'system', 'vm_options', 'use_sdk',
       'use_repository_packages', 'use_public_packages', 'builder_tag'];

  IOSink _sink;

  void done(TestCase test) {
    var name = test.displayName;
    var configuration = {};
    for (var key in INTERESTED_CONFIGURATION_PARAMETERS) {
      configuration[key] = test.configuration[key];
    }
    var outcome = '${test.lastCommandOutput.result(test)}';
    var expectations =
        test.expectedOutcomes.map((expectation) => "$expectation").toList();

    var commandResults = [];
    double totalDuration = 0.0;
    for (var command in test.commands) {
      var output = test.commandOutputs[command];
      if (output != null) {
        double duration = output.time.inMicroseconds/1000.0;
        totalDuration += duration;
        commandResults.add({
          'name': command.displayName,
          'duration': duration,
        });
      }
    }
    _writeTestOutcomeRecord({
      'name' : name,
      'configuration' : configuration,
      'test_result' : {
        'outcome' : outcome,
        'expected_outcomes' : expectations,
        'duration' : totalDuration,
        'command_results' : commandResults,
      },
    });
  }

  void allDone() {
    if (_sink != null) _sink.close();
  }

  void _writeTestOutcomeRecord(Map record) {
    if (_sink == null) {
      _sink = new File(TestUtils.testOutcomeFileName())
          .openWrite(mode: FileMode.APPEND);
    }
    _sink.write("${JSON.encode(record)}\n");
  }
}


class UnexpectedCrashDumpArchiver extends EventListener {
  void done(TestCase test) {
    if (test.unexpectedOutput && test.result == Expectation.CRASH) {
      var name = "core.dart.${test.lastCommandOutput.pid}";
      var file = new File(name);
      if (file.existsSync()) {
        // Find the binary - we assume this is the first part of the command
        var binName = test.lastCommandExecuted.toString().split(' ').first;
        var binFile = new File(binName);
        var binBaseName = new Path(binName).filename;
        if (binFile.existsSync()) {
          var tmpPath = new Path(Directory.systemTemp.path);
          var dir = new Path(TestUtils.mkdirRecursive(tmpPath,
              new Path('coredump_${test.lastCommandOutput.pid}')).path);
          TestUtils.copyFile(new Path(name), dir.append(name));
          TestUtils.copyFile(new Path(binName), dir.append(binBaseName));
          print("\nCopied core dump and binary for unexpected crash to: "
                "$dir");
        }
      }
    }
  }
}


class SummaryPrinter extends EventListener {
  void allTestsKnown() {
    if (SummaryReport.total > 0) {
      SummaryReport.printReport();
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
    var groupedStatuses = new Map<String, List<String>>();
    statusToConfigs.forEach((String status, List<String> configs) {
      var runtimeToConfiguration = new Map<String, List<String>>();
      for (String config in configs) {
        String runtime = _extractRuntime(config);
        var runtimeConfigs =
            runtimeToConfiguration.putIfAbsent(runtime, () => <String>[]);
        runtimeConfigs.add(config);
      }
      runtimeToConfiguration.forEach((String runtime,
                                      List<String> runtimeConfigs) {
        runtimeConfigs.sort((a, b) => a.compareTo(b));
        List<String> statuses =
            groupedStatuses.putIfAbsent('$runtime: $runtimeConfigs',
                                        () => <String>[]);
        statuses.add(status);
      });
    });

    print('\n\nNecessary status file updates:');
    groupedStatuses.forEach((String config, List<String> statuses) {
      print('');
      print('$config:');
      statuses.sort((a, b) => a.compareTo(b));
      for (String status in statuses) {
        print('  $status');
      }
    });
  }
}

class SkippedCompilationsPrinter extends EventListener {
  int _skippedCompilations = 0;

  void done(TestCase test) {
    for (var commandOutput in test.commandOutputs.values) {
      if (commandOutput.compilationSkipped)
        _skippedCompilations++;
    }
  }

  void allDone() {
    if (_skippedCompilations > 0) {
      print('\n$_skippedCompilations compilations were skipped because '
            'the previous output was already up to date\n');
    }
  }
}

class LeftOverTempDirPrinter extends EventListener {
  final MIN_NUMBER_OF_TEMP_DIRS = 50;

  static RegExp _getTemporaryDirectoryRegexp() {
    // These are the patterns of temporary directory names created by
    // 'Directory.systemTemp.createTemp()' on linux/macos and windows.
    if (['macos', 'linux'].contains(Platform.operatingSystem)) {
      return new RegExp(r'^temp_dir1_......$');
    } else {
      return new RegExp(r'tempdir-........-....-....-....-............$');
    }
  }

  static Stream<Directory> getLeftOverTemporaryDirectories() {
    var regExp = _getTemporaryDirectoryRegexp();
    return Directory.systemTemp.list().where(
        (FileSystemEntity fse) {
          if (fse is Directory) {
            if (regExp.hasMatch(new Path(fse.path).filename)) {
              return true;
            }
          }
          return false;
        });
  }

  void allDone() {
    getLeftOverTemporaryDirectories().length.then((int count) {
      if (count > MIN_NUMBER_OF_TEMP_DIRS) {
        DebugLogger.warning("There are ${count} directories "
                            "in the system tempdir "
                            "('${Directory.systemTemp.path}')! "
                            "Maybe left over directories?\n");
      }
    }).catchError((error) {
      DebugLogger.warning("Could not list temp directories, got: $error");
    });
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
  bool _printSummary;
  var _formatter;
  var _failureSummary = <String>[];
  var _failedTests= 0;

  TestFailurePrinter(this._printSummary,
                     [this._formatter = const Formatter()]);

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
    }
  }

  void allDone() {
    if (_printSummary) {
      if (!_failureSummary.isEmpty) {
        print('\n=== Failure summary:\n');
        for (String line in _failureSummary) {
          print(line);
        }
        print('');

        print(_buildSummaryEnd(_failedTests));
      }
    }
  }
}

class ProgressIndicator extends EventListener {
  ProgressIndicator(this._startTime);


  void testAdded() { _foundTests++; }

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
  CompactIndicator(DateTime startTime)
      : super(startTime);

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
  Formatter _formatter;

  CompactProgressIndicator(DateTime startTime, this._formatter)
      : super(startTime);

  void _printProgress() {
    var percent = ((_completedTests() / _foundTests) * 100).toInt().toString();
    var progressPadded = _pad(_allTestsKnown ? percent : '--', 3);
    var passedPadded = _pad(_passedTests.toString(), 5);
    var failedPadded = _pad(_failedTests.toString(), 5);
    Duration d = (new DateTime.now()).difference(_startTime);
    var progressLine =
        '\r[${_timeString(d)} | $progressPadded% | '
        '+${_formatter.passed(passedPadded)} | '
        '-${_formatter.failed(failedPadded)}]';
    stdout.write(progressLine);
  }
}


class VerboseProgressIndicator extends ProgressIndicator {
  VerboseProgressIndicator(DateTime startTime)
      : super(startTime);

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
  var _failureSummary = <String>[];

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
    print(_buildSummaryEnd(_failedTests));
  }
}


EventListener progressIndicatorFromName(String name,
                                        DateTime startTime,
                                        Formatter formatter) {
  switch (name) {
    case 'compact':
      return new CompactProgressIndicator(startTime, formatter);
    case 'line':
      return new LineProgressIndicator();
    case 'verbose':
      return new VerboseProgressIndicator(startTime);
    case 'status':
      return new ProgressIndicator(startTime);
    case 'buildbot':
      return new BuildbotProgressIndicator(startTime);
    default:
      assert(false);
      break;
  }
}
