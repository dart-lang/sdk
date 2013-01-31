// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A test configuration that generates a compact 1-line progress bar. The bar is
 * updated in-place before and after each test is executed. If all test pass,
 * you should only see a couple lines in the terminal. If a test fails, the
 * failure is shown and the progress bar continues to be updated below it.
 */
library compact_vm_config;

import 'dart:io';
import 'unittest.dart';
import 'vm_config.dart';

const String _GREEN = '\u001b[32m';
const String _RED = '\u001b[31m';
const String _NONE = '\u001b[0m';
const int MAX_LINE = 80;

class CompactVMConfiguration extends VMConfiguration {
  DateTime _start;
  int _pass = 0;
  int _fail = 0;

  void onInit() {
    super.onInit();
  }

  void onStart() {
    super.onStart();
    _start = new DateTime.now();
  }

  void onTestStart(TestCase test) {
    super.onTestStart(test);
    _progressLine(_start, _pass, _fail, test.description);
  }

  void onTestResult(TestCase test) {
    super.onTestResult(test);
    if (test.result == PASS) {
      _pass++;
      _progressLine(_start, _pass, _fail, test.description);
    } else {
      _fail++;
      _progressLine(_start, _pass, _fail, test.description);
      print('');
      if (test.message != '') {
        print(_indent(test.message));
      }

      if (test.stackTrace != null && test.stackTrace != '') {
        print(_indent(test.stackTrace));
      }
    }
  }

  String _indent(String str) {
    return str.split("\n").map((line) => "  $line").join("\n");
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    var success = false;
    if (passed == 0 && failed == 0 && errors == 0 && uncaughtError == null) {
      print('\nNo tests ran.');
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      _progressLine(_start, _pass, _fail, 'All tests pass', _GREEN);
      print('\nAll $passed tests passed.');
      success = true;
    } else {
      _progressLine(_start, _pass, _fail, 'Some tests fail', _RED);
      print('');
      if (uncaughtError != null) {
        print('Top-level uncaught error: $uncaughtError');
      }
      print('$passed PASSED, $failed FAILED, $errors ERRORS');
    }
  }

  int _lastLength = 0;

  final int _nonVisiblePrefix = 1 + _GREEN.length + _NONE.length;

  void _progressLine(DateTime startTime, int passed, int failed, String message,
      [String color = _NONE]) {
    var duration = (new DateTime.now()).difference(startTime);
    var buffer = new StringBuffer();
    // \r moves back to the beginnig of the current line.
    buffer.add('\r${_timeString(duration)} ');
    buffer.add(_GREEN);
    buffer.add('+');
    buffer.add(passed);
    buffer.add(_NONE);
    if (failed != 0) buffer.add(_RED);
    buffer.add(' -');
    buffer.add(failed);
    if (failed != 0) buffer.add(_NONE);
    buffer.add(': ');
    buffer.add(color);

    int nonVisible = _nonVisiblePrefix + color.length  +
        (failed != 0 ? (_RED.length + _NONE.length) : 0);
    int len = buffer.length - nonVisible;
    var mx = MAX_LINE - len;
    buffer.add(_snippet(message, MAX_LINE - len));
    buffer.add(_NONE);

    // Pad the rest of the line so that it looks erased.
    len = buffer.length - nonVisible - _NONE.length;
    if (len > _lastLength) {
      _lastLength = len;
    } else {
      while (len < _lastLength) {
        buffer.add(' ');
        _lastLength--;
      }
    }
    stdout.writeString(buffer.toString());
  }

  String _padTime(int time) =>
    (time == 0) ? '00' : ((time < 10) ? '0$time' : '$time');

  String _timeString(Duration duration) {
    var min = duration.inMinutes;
    var sec = duration.inSeconds % 60;
    return '${_padTime(min)}:${_padTime(sec)}';
  }

  String _snippet(String text, int maxLength) {
    // Return the full message if it fits
    if (text.length <= maxLength) return text;

    // If we can fit the first and last three words, do so.
    var words = text.split(' ');
    if (words.length > 1) {
      int i = words.length;
      var len = words.first.length + 4;
      do {
        len += 1 + words[--i].length;
      } while (len <= maxLength && i > 0);
      if (len > maxLength || i == 0) i++;
      if (i < words.length - 4) {
        // Require at least 3 words at the end.
        var buffer = new StringBuffer();
        buffer.add(words.first);
        buffer.add(' ...');
        for (; i < words.length; i++) {
          buffer.add(' ');
          buffer.add(words[i]);
        }
        return buffer.toString();
      }
    }

    // Otherwise truncate to return the trailing text, but attempt to start at
    // the beginning of a word.
    var res = text.substring(text.length - maxLength + 4);
    var firstSpace = res.indexOf(' ');
    if (firstSpace > 0) {
      res = res.substring(firstSpace);
    }
    return '...$res';
  }
}

void useCompactVMConfiguration() {
  if (config != null) return;
  configure(new CompactVMConfiguration());
}
