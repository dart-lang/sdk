// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_line_config;

import 'dart:io';

import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/utils.dart';

const _GREEN = '\u001b[32m';
const _RED = '\u001b[31m';
const _MAGENTA = '\u001b[35m';
const _NONE = '\u001b[0m';

/// Pretty Unicode characters!
const _CHECKBOX = '\u2713';
const _BALLOT_X = '\u2717';
const _LAMBDA   = '\u03bb';

/// A custom unittest configuration for running the pub tests from the
/// command-line and generating human-friendly output.
class CommandLineConfiguration extends Configuration {
  void onInit() {
    // Do nothing. Overridden to prevent the base class from printing.
  }

  void onTestResult(TestCase testCase) {
    var result;
    switch (testCase.result) {
      case PASS: result = '$_GREEN$_CHECKBOX$_NONE'; break;
      case FAIL: result = '$_RED$_BALLOT_X$_NONE'; break;
      case ERROR: result = '$_MAGENTA?$_NONE'; break;
    }
    print('$result ${testCase.description}');

    if (testCase.message != '') {
      print(_indent(testCase.message));
    }

    _printStackTrace(testCase.stackTrace);

    currentTestCase = null;
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    var success = false;
    if (uncaughtError != null) {
      print('Top-level uncaught error: $uncaughtError');
    } else if (errors != 0) {
      print('${_GREEN}$passed${_NONE} passed, ${_RED}$failed${_NONE} failed, '
            '${_MAGENTA}$errors${_NONE} errors.');
    } else if (failed != 0) {
      print('${_GREEN}$passed${_NONE} passed, ${_RED}$failed${_NONE} '
            'failed.');
    } else if (passed == 0) {
      print('No tests found.');
    } else {
      print('All ${_GREEN}$passed${_NONE} tests passed!');
      success = true;
    }
  }

  void onDone(bool success) {
    if (!success) exit(1);
  }

  void _printStackTrace(String stackTrace) {
    if (stackTrace == null || stackTrace == '') return;

    // Parse out each stack entry.
    var stack = [];
    for (var line in stackTrace.split('\n')) {
      if (line.trim() == '') continue;
      stack.add(new _StackFrame(line));
    }

    if (stack.length == 0) return;

    // Find the common prefixes of the paths.
    var common = 0;
    while (true) {
      var matching = true;
      var c;
      for (var frame in stack) {
        if (frame.isCore) continue;
        if (c == null) c = frame.library[common];

        if (frame.library.length <= common || frame.library[common] != c) {
          matching = false;
          break;
        }
      }

      if (!matching) break;
      common++;
    }

    // Remove them.
    if (common > 0) {
      for (var frame in stack) {
        if (frame.isCore) continue;
        frame.library = frame.library.substring(common);
      }
    }

    // Figure out the longest path so we know how much to pad.
    int longest = stack.mappedBy((frame) => frame.location.length).max();

    // Print out the stack trace nicely formatted.
    for (var frame in stack) {
      print('  ${_padLeft(frame.location, longest)}  ${frame.member}');
    }

    print('');
  }

  String _padLeft(String string, int length) {
    if (string.length >= length) return string;

    var result = new StringBuffer();
    result.add(string);
    for (var i = 0; i < length - string.length; i++) {
      result.add(' ');
    }

    return result.toString();
  }

  String _indent(String str) {
    // TODO(nweiz): Use this simpler code once issue 2980 is fixed.
    // return str.replaceAll(new RegExp("^", multiLine: true), "  ");
    return Strings.join(str.split("\n").mappedBy((line) => "  $line"), "\n");
  }
}

class _StackFrame {
  static final fileRegExp = new RegExp(
      r'#\d+\s+(.*) \((file:///.+):(\d+):(\d+)\)');
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

    var member = match[1].replaceAll("<anonymous closure>", _LAMBDA);
    return new _StackFrame._(isCore, match[2], match[3], match[4], member);
  }
}