// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.super_mixin;

import 'dart:io';

import 'package:analyzer_cli/src/ansi.dart' as ansi;
import 'package:analyzer_cli/src/driver.dart' show Driver, errorSink, outSink;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

/// End-to-end test for --supermixins.
///
/// Most super mixin tests are in Analyzer, but this verifies the option is
/// working and producing extra errors as expected.
///
/// Generally we don't want a lot of cases here as it requires spinning up a
/// full analysis context.
void main() {
  group('--supermixins', () {
    StringSink savedOutSink, savedErrorSink;
    int savedExitCode;

    setUp(() {
      ansi.runningTests = true;
      savedOutSink = outSink;
      savedErrorSink = errorSink;
      savedExitCode = exitCode;
      outSink = new StringBuffer();
      errorSink = new StringBuffer();
    });

    tearDown(() {
      outSink = savedOutSink;
      errorSink = savedErrorSink;
      exitCode = savedExitCode;
      ansi.runningTests = false;
    });

    test('produces errors when option absent', () async {
      var testPath = path.join(testDirectory, 'data/super_mixin_example.dart');
      await new Driver(isTesting: true).start([testPath]);

      expect(exitCode, 3);
      var stdout = outSink.toString();
      expect(
          stdout,
          contains(
              "error • The class 'C' can't be used as a mixin because it extends a class other than Object"));
      expect(
          stdout,
          contains(
              "error • The class 'C' can't be used as a mixin because it references 'super'"));
      expect(stdout, contains('2 errors found.'));
      expect(errorSink.toString(), '');
    });

    test('produces no errors when option present', () async {
      var testPath = path.join(testDirectory, 'data/super_mixin_example.dart');
      await new Driver(isTesting: true).start(['--supermixin', testPath]);

      expect(exitCode, 0);
      var stdout = outSink.toString();
      expect(stdout, contains('No issues found'));
    });
  });
}
