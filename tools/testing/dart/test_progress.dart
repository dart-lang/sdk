// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_progress");

#import("test_runner.dart");

class ProgressIndicator {
  ProgressIndicator(this._startTime);

  factory ProgressIndicator.fromName(String name, Date startTime) {
    switch (name) {
      case 'compact':
        return new CompactProgressIndicator(startTime);
      case 'line':
        return new LineProgressIndicator(startTime);
      case 'verbose':
        return new VerboseProgressIndicator(startTime);
      case 'status':
        return new StatusProgressIndicator(startTime);
      case 'buildbot':
        return new BuildbotProgressIndicator(startTime);
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
  }

  abstract allDone();
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

  String _timeString() {
    Duration d = (new Date.now()).difference(_startTime);
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
  Date _startTime;
}


class CompactProgressIndicator extends ProgressIndicator {
  CompactProgressIndicator(Date startTime) : super(startTime);

  void allDone() {
    stdout.write('\n'.charCodes());
  }

  void _printProgress() {
    var percent = ((_completedTests() / _foundTests) * 100).floor().toString();
    var percentPadded = _pad(percent, 5);
    var passedPadded = _pad(_passedTests.toString(), 5);
    var failedPadded = _pad(_failedTests.toString(), 5);
    var progressLine =
        '\r[${_timeString()} | $percentPadded% | ' +
        '+$passedPadded | -$failedPadded]';
    stdout.write(progressLine.charCodes());
  }

  void _printStartProgress(TestCase test) => _printProgress();
  void _printDoneProgress(TestCase test) => _printProgress();
}


class LineProgressIndicator extends ProgressIndicator {
  LineProgressIndicator(Date startTime) : super(startTime);

  void allDone() {
    _printStatus();
  }

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
  VerboseProgressIndicator(Date startTime) : super(startTime);

  void allDone() {
    _printStatus();
  }

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
  StatusProgressIndicator(Date startTime) : super(startTime);

  void allDone() {
    _printStatus();
  }

  void _printStartProgress(TestCase test) {
  }

  void _printDoneProgress(TestCase test) {
  }
}


class BuildbotProgressIndicator extends ProgressIndicator {
  BuildbotProgressIndicator(Date startTime) : super(startTime);

  void allDone() {
    _printStatus();
  }

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
