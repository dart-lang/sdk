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
    var regexp = new RegExp(r'#\d+\s+(.*) \(file:///([^)]+)\)');
    var stack = [];
    for (var line in stackTrace.split('\n')) {
      if (line.trim() == '') continue;

      var match = regexp.firstMatch(line);
      if (match == null) throw "Couldn't clean up stack trace line '$line'.";
      stack.add(new Pair(match[2], match[1]));
    }

    if (stack.length == 0) return;

    // Find the common prefixes of the paths.
    var common = 0;
    while (true) {
      var matching = true;
      // TODO(bob): Handle empty stack.
      var c = stack[0].first[common];
      for (var pair in stack) {
        if (pair.first.length <= common || pair.first[common] != c) {
          matching = false;
          break;
        }
      }

      if (!matching) break;
      common++;
    }

    // Remove them.
    if (common > 0) {
      for (var pair in stack) {
        pair.first = pair.first.substring(common);
      }
    }

    // Figure out the longest path so we know how much to pad.
    int longest = stack.mappedBy((pair) => pair.first.length).max();

    // Print out the stack trace nicely formatted.
    for (var pair in stack) {
      var path = pair.first;
      path = path.replaceFirst(':', ' ');
      print('  ${_padLeft(path, longest)}  ${pair.last}');
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
