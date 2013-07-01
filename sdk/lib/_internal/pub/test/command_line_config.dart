// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_line_config;

import 'dart:io';
import 'dart:math' as math;

import 'package:pathos/path.dart' as path;
import 'package:unittest/unittest.dart';
import '../lib/src/utils.dart';

/// Pretty Unicode characters!
final _checkbox = getSpecial('\u2713', 'PASS');
final _ballotX  = getSpecial('\u2717', 'FAIL');
final _lambda   = getSpecial('\u03bb', '<fn>');

final _green = getSpecial('\u001b[32m');
final _red = getSpecial('\u001b[31m');
final _magenta = getSpecial('\u001b[35m');
final _none = getSpecial('\u001b[0m');

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

    if (testCase.stackTrace != null) {
      print(_indent(testCase.stackTrace.toString()));
    }

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
}
