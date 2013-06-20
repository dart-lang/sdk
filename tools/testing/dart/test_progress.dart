// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_progress;

import "dart:io";
import "dart:io" as io;
import "http_server.dart" as http_server;
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
  output.add('Actual: ${test.lastCommandOutput.result}');
  if (!test.lastCommandOutput.hasTimedOut && test.info != null) {
    if (test.lastCommandOutput.incomplete && !test.info.hasCompileError) {
      output.add('Unexpected compile-time error.');
    } else {
      if (test.info.hasCompileError) {
        output.add('Compile-time error expected.');
      }
      if (test.info.hasRuntimeError) {
        output.add('Runtime error expected.');
      }
    }
  }
  for (var i = 0; i < test.commands.length; i++) {
    var command = test.commands[i];
    var commandOutput = test.commandOutputs[command];
    if (commandOutput != null) {
      output.add("CommandOutput[$i]:");
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
        if (command.isPixelTest) {
          output.add('DRT pixel test failed! stdout is not printed because it '
                     'contains binary data!');
        } else {
          output.addAll(getLinesWithoutCarriageReturn(commandOutput.stdout));
        }
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
    output.add('Command[$i]: $command');
    if (commandOutput != null) {
      output.add('Took ${commandOutput.time}');
    } else {
      output.add('Did not run');
    }
  }
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
  void start(TestCase test) { }
  void done(TestCase test) { }
  void allTestsKnown() { }
  void allDone() { }
}

class ExitCodeSetter extends EventListener {
  void done(TestCase test) {
    if (test.lastCommandOutput.unexpectedOutput) {
      io.exitCode = 1;
    }
  }
}

class FlakyLogWriter extends EventListener {
  void done(TestCase test) {
    if (test.isFlaky && test.lastCommandOutput.result != PASS) {
      var buf = new StringBuffer();
      for (var l in _buildFailureOutput(test)) {
        buf.write("$l\n");
      }
      _appendToFlakyFile(buf.toString());
    }
  }

  void _appendToFlakyFile(String msg) {
    var file = new File(TestUtils.flakyFileName());
    var fd = file.openSync(FileMode.APPEND);
    fd.writeStringSync(msg);
    fd.closeSync();
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
  List<TestCase> _tests = <TestCase>[];
  DateTime _startTime;

  TimingPrinter(this._startTime);

  void done(TestCase testCase) {
    _tests.add(testCase);
  }

  void allDone() {
    // TODO: We should take all the commands into account
    Duration d = (new DateTime.now()).difference(_startTime);
    print('\n--- Total time: ${_timeString(d)} ---');
    _tests.sort((a, b) {
      Duration aDuration = a.lastCommandOutput.time;
      Duration bDuration = b.lastCommandOutput.time;
      return bDuration.inMilliseconds - aDuration.inMilliseconds;
    });
    for (int i = 0; i < 20 && i < _tests.length; i++) {
      var name = _tests[i].displayName;
      var duration = _tests[i].lastCommandOutput.time;
      var configuration = _tests[i].configurationString;
      print('${duration} - $configuration $name');
    }
  }
}

class StatusFileUpdatePrinter extends EventListener {
  var statusToConfigs = new Map<String, List<String>>();
  var _failureSummary = <String>[];

  void done(TestCase test) {
    if (test.lastCommandOutput.unexpectedOutput) {
      _printFailureOutput(test);
    }
  }

  void allDone() {
    _printFailureSummary();
  }


  void _printFailureOutput(TestCase test) {
    String status = '${test.displayName}: ${test.lastCommandOutput.result}';
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

  Path _tempDir() {
    // Dir will be located in the system temporary directory.
    var dir = new Directory('').createTempSync();
    var path = new Path(dir.path).directoryPath;
    dir.deleteSync();
    return path;
  }

  void allDone() {
    var count = 0;
    var systemTempDir = _tempDir();
    var lister = new Directory.fromPath(systemTempDir).list().listen(
        (FileSystemEntity fse) {
          if (fse is Directory) count++;
        },
        onError: (error) {
          DebugLogger.warning("Could not list temp directories, got: $error");
        },
        onDone: () {
          if (count > MIN_NUMBER_OF_TEMP_DIRS) {
            DebugLogger.warning("There are ${count} directories "
                                "in the system tempdir ('$systemTempDir')! "
                                "Maybe left over directories?\n");
      }
    });
  }
}

class LineProgressIndicator extends EventListener implements ProgressIndicator {
  void done(TestCase test) {
    var status = 'pass';
    if (test.lastCommandOutput.unexpectedOutput) {
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
    if (test.lastCommandOutput.unexpectedOutput) {
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

  factory ProgressIndicator.fromName(String name,
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

  void testAdded() { _foundTests++; }

  void start(TestCase test) {
    _printStartProgress(test);
  }

  void done(TestCase test) {
    if (test.lastCommandOutput.unexpectedOutput) {
      _failedTests++;
    } else {
      _passedTests++;
    }
    _printDoneProgress(test);
  }

  void allTestsKnown() {
    _allTestsKnown = true;
  }

  void _printStartProgress(TestCase test) {}
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

  void _printStartProgress(TestCase test) => _printProgress();
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

  void _printStartProgress(TestCase test) {
    print('Starting ${test.configurationString} ${test.displayName}...');
  }

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.lastCommandOutput.unexpectedOutput) {
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
    if (test.lastCommandOutput.unexpectedOutput) {
      _failureSummary.addAll(_buildFailureOutput(test));
    }
  }

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.lastCommandOutput.unexpectedOutput) {
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
