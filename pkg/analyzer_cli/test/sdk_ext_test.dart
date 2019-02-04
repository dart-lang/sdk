// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that sdk extensions are properly detected in various scenarios.
import 'dart:io';

import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer_cli/src/driver.dart' show Driver, errorSink, outSink;
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

main() {
  group('Sdk extensions', () {
    StringSink savedOutSink, savedErrorSink;
    int savedExitCode;
    ExitHandler savedExitHandler;

    setUp(() {
      savedOutSink = outSink;
      savedErrorSink = errorSink;
      savedExitHandler = exitHandler;
      savedExitCode = exitCode;
      exitHandler = (code) => exitCode = code;
      outSink = new StringBuffer();
      errorSink = new StringBuffer();
    });
    tearDown(() {
      outSink = savedOutSink;
      errorSink = savedErrorSink;
      exitCode = savedExitCode;
      exitHandler = savedExitHandler;
    });

    test('.packages file specified', () async {
      String testDir = path.join(testDirectory, 'data', 'packages_file');
      Driver driver = new Driver(isTesting: true);
      await driver.start([
        '--packages',
        path.join(testDir, '_packages'),
        path.join(testDir, 'sdk_ext_user.dart')
      ]);

      DartSdk sdk = driver.sdk;
      expect(sdk, const TypeMatcher<FolderBasedDartSdk>());
      expect((sdk as FolderBasedDartSdk).useSummary, isFalse);

      expect(exitCode, 0);
    });
  });
}
