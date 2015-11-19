// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn("vm")

/// Test that sdk extensions are properly detected in various scenarios.
library analyzer_cli.test.sdk_ext;

import 'dart:io';

import 'package:analyzer_cli/src/driver.dart' show Driver, errorSink, outSink;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

main() {
  group('Sdk extensions', () {
    StringSink savedOutSink, savedErrorSink;
    int savedExitCode;
    Directory savedCurrentDirectory;
    setUp(() {
      savedOutSink = outSink;
      savedErrorSink = errorSink;
      savedExitCode = exitCode;
      outSink = new StringBuffer();
      errorSink = new StringBuffer();
      savedCurrentDirectory = Directory.current;
    });
    tearDown(() {
      outSink = savedOutSink;
      errorSink = savedErrorSink;
      exitCode = savedExitCode;
      Directory.current = savedCurrentDirectory;
    });

    test('--packages option supplied', () async {
      var testDir = path.join(testDirectory, 'data', 'no_packages_file');
      Directory.current = new Directory(testDir);
      var packagesPath = path.join('..', 'packages_file', '.packages');
      new Driver().start(['--packages', packagesPath, 'sdk_ext_user.dart']);

      expect(exitCode, 0);
    });

    test('.packages file present', () async {
      var testDir = path.join(testDirectory, 'data', 'packages_file');
      Directory.current = new Directory(testDir);
      new Driver().start(['sdk_ext_user.dart']);

      expect(exitCode, 0);
    });
  });
}
