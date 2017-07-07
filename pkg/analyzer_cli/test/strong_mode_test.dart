// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.strong_mode;

import 'dart:io';

import 'package:analyzer_cli/src/driver.dart' show Driver, errorSink, outSink;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'driver_test.dart';
import 'utils.dart';

/// End-to-end test for --strong checking.
///
/// Most strong mode tests are in Analyzer, but this verifies the option is
/// working and producing extra errors as expected.
///
/// Generally we don't want a lot of cases here as it requires spinning up a
/// full analysis context.
///
// TODO(pq): fix tests to run safely on the bots
// https://github.com/dart-lang/sdk/issues/25001
main() {}
not_main() {
  group('--strong', () {
    StringSink savedOutSink, savedErrorSink;
    int savedExitCode;
    setUp(() {
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
    });

    test('produces stricter errors', () async {
      var testPath = path.join(testDirectory, 'data/strong_example.dart');
      new Driver(isTesting: true)
          .start(['--options', emptyOptionsFile, '--strong', testPath]);

      expect(exitCode, 3);
      var stdout = outSink.toString();
      expect(stdout, contains('[error] Invalid override'));
      expect(stdout, contains('[error] Type check failed'));
      expect(stdout, contains('2 errors found.'));
      expect(errorSink.toString(), '');
    });
  });
}
