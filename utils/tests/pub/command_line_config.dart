// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_line_config;

import 'dart:io';
import 'dart:math' as math;

import 'package:pathos/path.dart' as path;
import 'package:unittest/unittest.dart';
import '../../pub/utils.dart';

/// Gets a "special" string (ANSI escape or Unicode). On Windows, returns
/// something else since those aren't supported.
String _getSpecial(String color, [String onWindows = '']) {
  // No ANSI escapes on windows.
  if (Platform.operatingSystem == 'windows') return onWindows;
  return color;
}

/// Pretty Unicode characters!
final _checkbox = _getSpecial('\u2713', 'PASS');
final _ballotX  = _getSpecial('\u2717', 'FAIL');
final _lambda   = _getSpecial('\u03bb', '<fn>');

final _green = _getSpecial('\u001b[32m');
final _red = _getSpecial('\u001b[31m');
final _magenta = _getSpecial('\u001b[35m');
final _none = _getSpecial('\u001b[0m');

/// A custom unittest configuration for running the pub tests from the
/// command-line and generating human-friendly output.
class CommandLineConfiguration extends Configuration {
  void onInit() {
    // Do nothing. Overridden to prevent the base class from printing.
  }

  void onTestResult(TestCase testCase) {
    var result;
    switch (testCase.result) {
      case PASS: result = '$_green$_checkbox$_none'; break;
      case FAIL: result = '$_red$_ballotX$_none'; break;
      case ERROR: result = '$_magenta?$_none'; break;
    }
    print('$result ${testCase.description}');

    if (testCase.message != '') {
      print(_indent(testCase.message));
    }

    _printStackTrace(testCase.stackTrace);

    super.onTestResult(testCase);
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    var success = false;
    if (uncaughtError != null) {
      print('Top-level uncaught error: $uncaughtError');
    } else if (errors != 0) {
      print('${_green}$passed${_none} passed, ${_red}$failed${_none} failed, '
            '${_magenta}$errors${_none} errors.');
    } else if (failed != 0) {
      print('${_green}$passed${_none} passed, ${_red}$failed${_none} '
            'failed.');
    } else if (passed == 0) {
      print('No tests found.');
    } else {
      print('All ${_green}$passed${_none} tests passed!');
      success = true;
    }
  }

  void onDone(bool success) {
    if (!success) exit(1);
  }

  void _printStackTrace(String stackTrace) {
    if (stackTrace == null || stackTrace == '') return;

    print('');

    // Parse out each stack entry.
    var stack = [];
    for (var line in stackTrace.split('\n')) {
      if (line.trim() == '') continue;
      stack.add(new _StackFrame(line));
    }

    if (stack.length == 0) return;

    // Figure out the longest path so we know how much to pad.
    int longest = stack.map((frame) => frame.location.length).reduce(math.max);

    // Print out the stack trace nicely formatted.
    for (var frame in stack) {
      print('  ${_padLeft(frame.location, longest)}  ${frame.member}');
    }

    print('');
  }

  String _padLeft(String string, int length) {
    if (string.length >= length) return string;

    var result = new StringBuffer();
    result.write(string);
    for (var i = 0; i < length - string.length; i++) {
      result.write(' ');
    }

    return result.toString();
  }

  String _indent(String str) {
    // TODO(nweiz): Use this simpler code once issue 2980 is fixed.
    // return str.replaceAll(new RegExp("^", multiLine: true), "  ");
    return str.split("\n").map((line) => "  $line").join("\n");
  }
}

class _StackFrame {
  static final fileRegExp = new RegExp(
      r'#\d+\s+(.*) \(file://(/.+):(\d+):(\d+)\)');
  static final coreRegExp = new RegExp(r'#\d+\s+(.*) \((.+):(\d+):(\d+)\)');

  /// If `true`, then this stack frame is for a library built into Dart and
  /// not a regular file path.
  final bool isCore;

  /// The path to the library or the library name if a core library.
  String library;

  /// The line number.
  final String line;

  /// The column number.
  final String column;

  /// The member where the error occurred.
  final String member;

  /// A formatted description of the code location.
  String get location => '$library $line:$column';

  _StackFrame._(this.isCore, this.library, this.line, this.column, this.member);

  factory _StackFrame(String text) {
    var match = fileRegExp.firstMatch(text);
    var isCore = false;

    if (match == null) {
      match = coreRegExp.firstMatch(text);
      if (match == null) throw "Couldn't parse stack trace line '$text'.";
      isCore = true;
    }

    var library = match[2];
    if (!isCore) {
      // Make the library path relative to the entrypoint.
      library = path.relative(library);
    }

    var member = match[1].replaceAll("<anonymous closure>", _lambda);
    return new _StackFrame._(isCore, library, match[3], match[4], member);
  }
}
