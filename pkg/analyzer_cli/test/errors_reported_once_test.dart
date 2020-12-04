// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils.dart';

void main() {
  defineReflectiveTests(ErrorsReportedOnceTest);
}

@reflectiveTest
class ErrorsReportedOnceTest {
  StringSink savedOutSink, savedErrorSink;
  int savedExitCode;
  ExitHandler savedExitHandler;

  void setUp() {
    savedOutSink = outSink;
    savedErrorSink = errorSink;
    savedExitHandler = exitHandler;
    savedExitCode = exitCode;
    exitHandler = (code) => exitCode = code;
    outSink = StringBuffer();
    errorSink = StringBuffer();
  }

  void tearDown() {
    outSink = savedOutSink;
    errorSink = savedErrorSink;
    exitCode = savedExitCode;
    exitHandler = savedExitHandler;
  }

  Future<void> test_once() async {
    var testDir = path.join(testDirectory, 'data', 'errors_reported_once');
    var driver = Driver();
    await driver.start(
        [path.join(testDir, 'foo.dart'), path.join(testDir, 'bar.dart')]);

    expect(exitCode, 0);

    // Ensure that we only have one copy of the error.
    final unusedWarning = 'Unused import';
    var output = outSink.toString();
    expect(output, contains(unusedWarning));
    expect(unusedWarning.allMatches(output).toList(), hasLength(1));
  }

  Future<void> test_once_machine() async {
    var testDir = path.join(testDirectory, 'data', 'errors_reported_once');
    var driver = Driver();
    await driver.start([
      '--format',
      'machine',
      path.join(testDir, 'foo.dart'),
      path.join(testDir, 'bar.dart')
    ]);

    expect(exitCode, 0);

    // Ensure that we only have one copy of the error.
    final unusedWarning = 'Unused import';
    var output = errorSink.toString();
    expect(output, contains(unusedWarning));
    expect(unusedWarning.allMatches(output).toList(), hasLength(1));
  }
}
