// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils.dart';

main() {
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
    outSink = new StringBuffer();
    errorSink = new StringBuffer();
  }

  void tearDown() {
    outSink = savedOutSink;
    errorSink = savedErrorSink;
    exitCode = savedExitCode;
    exitHandler = savedExitHandler;
  }

  test_once() async {
    String testDir = path.join(testDirectory, 'data', 'errors_reported_once');
    Driver driver = new Driver();
    await driver.start(
        [path.join(testDir, 'foo.dart'), path.join(testDir, 'bar.dart')]);

    expect(exitCode, 0);

    // Ensure that we only have one copy of the error.
    final String unusedWarning = 'Unused import';
    String output = outSink.toString();
    expect(output, contains(unusedWarning));
    expect(unusedWarning.allMatches(output).toList(), hasLength(1));
  }
}
