// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_progress");

#import("test_runner.dart");
#import("test_suite.dart");

class ProgressIndicator {
  ProgressIndicator(this._startTime, this._printTiming) : _tests = [];

  factory ProgressIndicator.fromName(String name,
                                     Date startTime,
                                     bool printTiming) {
    switch (name) {
      case 'compact':
        return new CompactProgressIndicator(startTime, printTiming);
      case 'color':
        return new ColorProgressIndicator(startTime, printTiming);
      case 'line':
        return new LineProgressIndicator(startTime, printTiming);
      case 'verbose':
        return new VerboseProgressIndicator(startTime, printTiming);
      case 'status':
        return new StatusProgressIndicator(startTime, printTiming);
      case 'buildbot':
        return new BuildbotProgressIndicator(startTime, printTiming);
      default:
        assert(false);
        break;
    }
  }

  void testAdded() => _foundTests++;

  void start(TestCase test) {
    _printStartProgress(test);
  }

  void done(TestCase test) {
    if (test.output.unexpectedOutput) {
      _failedTests++;
      _printFailureOutput(test);
    } else {
      _passedTests++;
    }
    _printDoneProgress(test);
    // If we need to print timing information we hold on to all completed
    // tests.
    if (_printTiming) _tests.add(test);
  }

  void allTestsKnown() {
    if (!_allTestsKnown) SummaryReport.printReport();
    _allTestsKnown = true;
  }

  void _printTimingInformation() {
    if (_printTiming) {
      Duration d = (new Date.now()).difference(_startTime);
      print('\n--- Total time: ${_timeString(d)} ---');
      _tests.sort((a, b) {
        Duration aDuration = a.output.time;
        Duration bDuration = b.output.time;
        return bDuration.inMilliseconds - aDuration.inMilliseconds;
      });
      for (int i = 0; i < 20 && i < _tests.length; i++) {
        var name = _tests[i].displayName;
        var duration = _tests[i].output.time;
        print('${duration} - $name');
      }
    }
  }

  void allDone() {
    _printStatus();
    _printTimingInformation();
    exit(_failedTests > 0 ? 1 : 0);
  }

  abstract _printStartProgress();
  abstract _printDoneProgress();

  String _pad(String s, int length) {
    StringBuffer buffer = new StringBuffer();
    for (int i = s.length; i < length; i++) {
      buffer.add(' ');
    }
    buffer.add(s);
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

  void _printFailureOutput(TestCase test) {
    print('\nFAILED: ${test.displayName}');
    StringBuffer expected = new StringBuffer();
    expected.add('Expected: ');
    for (var expectation in test.expectedOutcomes) {
      expected.add('$expectation ');
    }
    print(expected.toString());
    print('Actual: ${test.output.result}');
    if (!test.output.stdout.isEmpty()) {
      print('\nstdout:');
      test.output.stdout.forEach((s) => print(s));
    }
    if (!test.output.stderr.isEmpty()) {
      print('\nstderr:');
      test.output.stderr.forEach((s) => print(s));
    }
    print('\nCommand line: ${test.commandLine}');
  }

  void _printStatus() {
    if (_failedTests == 0) {
      print('\n===');
      print('=== All tests succeeded');
      print('===\n');
    } else {
      var pluralSuffix = _failedTests != 1 ? 's' : '';
      print('\n===');
      print('=== ${_failedTests} test$pluralSuffix failed');
      print('===\n');
    }
  }

  int _completedTests() => _passedTests + _failedTests;

  int _foundTests = 0;
  int _passedTests = 0;
  int _failedTests = 0;
  bool _allTestsKnown = false;
  Date _startTime;
  bool _printTiming;
  List<TestCase> _tests;
}


class CompactIndicator extends ProgressIndicator {
  CompactIndicator(Date startTime, bool printTiming)
      : super(startTime, printTiming);

  void allDone() {
    stdout.write('\n'.charCodes());
    _printTimingInformation();
    stdout.close();
    exit(_failedTests > 0 ? 1 : 0);
  }

  void _printStartProgress(TestCase test) => _printProgress();
  void _printDoneProgress(TestCase test) => _printProgress();

  String _nextSpinner() {
    _spinnerIndex = (_spinnerIndex + 1) % 4;
    return _spinners[_spinnerIndex];
  }

  static int _spinnerIndex = 0;
  static List<String> _spinners = const ['- ', '\\ ', '| ', '/ '];
}


class CompactProgressIndicator extends CompactIndicator {
  CompactProgressIndicator(Date startTime, bool printTiming)
      : super(startTime, printTiming);

  void _printProgress() {
    var percent = ((_completedTests() / _foundTests) * 100).floor().toString();
    var progressPadded = _pad(_allTestsKnown ? percent : _nextSpinner(), 5);
    var passedPadded = _pad(_passedTests.toString(), 5);
    var failedPadded = _pad(_failedTests.toString(), 5);
    Duration d = (new Date.now()).difference(_startTime);
    var progressLine =
        '\r[${_timeString(d)} | $progressPadded% | ' +
        '+$passedPadded | -$failedPadded]';
    stdout.write(progressLine.charCodes());
  }
}


class ColorProgressIndicator extends CompactIndicator {
  ColorProgressIndicator(Date startTime, bool printTiming)
      : super(startTime, printTiming);

  static int GREEN = 32;
  static int RED = 31;
  static int NONE = 0;

  addColorWrapped(List<int> codes, String string, int color) {
    codes.add(27);
    codes.addAll('[${color}m'.charCodes());
    codes.addAll(string.charCodes());
    codes.add(27);
    codes.addAll('[0m'.charCodes());
  }

  void _printProgress() {
    var percent = ((_completedTests() / _foundTests) * 100).floor().toString();
    var progressPadded = _pad(_allTestsKnown ? percent : _nextSpinner(), 5);
    var passedPadded = _pad(_passedTests.toString(), 5);
    var failedPadded = _pad(_failedTests.toString(), 5);
    Duration d = (new Date.now()).difference(_startTime);
    var progressLine = [];
    progressLine.addAll('\r[${_timeString(d)} | $progressPadded% | '.charCodes());
    addColorWrapped(progressLine, '+$passedPadded ', GREEN);
    progressLine.addAll('| '.charCodes());
    var failedColor = (_failedTests != 0) ? RED : NONE;
    addColorWrapped(progressLine, '-$failedPadded', failedColor);
    progressLine.addAll(']'.charCodes());
    stdout.write(progressLine);
  }
}


class LineProgressIndicator extends ProgressIndicator {
  LineProgressIndicator(Date startTime, bool printTiming)
      : super(startTime, printTiming);

  void _printStartProgress(TestCase test) {
  }

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.output.unexpectedOutput) {
      status = 'fail';
    }
    print('Done ${test.displayName}: $status');
  }
}


class VerboseProgressIndicator extends ProgressIndicator {
  VerboseProgressIndicator(Date startTime, bool printTiming)
      : super(startTime, bool printTiming);

  void _printStartProgress(TestCase test) {
    print('Starting ${test.displayName}...');
  }

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.output.unexpectedOutput) {
      status = 'fail';
    }
    print('Done ${test.displayName}: $status');
  }
}


class StatusProgressIndicator extends ProgressIndicator {
  StatusProgressIndicator(Date startTime, bool printTiming)
      : super(startTime, printTiming);

  void _printStartProgress(TestCase test) {
  }

  void _printDoneProgress(TestCase test) {
  }
}


class BuildbotProgressIndicator extends ProgressIndicator {
  BuildbotProgressIndicator(Date startTime, bool printTiming)
      : super(startTime, printTiming);

  void _printStartProgress(TestCase test) {
  }

  void _printDoneProgress(TestCase test) {
    var status = 'pass';
    if (test.output.unexpectedOutput) {
      status = 'fail';
    }
    var percent = ((_completedTests() / _foundTests) * 100).toInt().toString();
    print('Done ${test.displayName}: $status');
    print('@@@STEP_CLEAR@@@');
    print('@@@STEP_TEXT@ $percent% +$_passedTests -$_failedTests @@@');
  }
}
