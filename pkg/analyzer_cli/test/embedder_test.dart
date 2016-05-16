// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer_cli/src/driver.dart' show Driver, errorSink, outSink;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initializeTestEnvironment();

  group('_embedder.yaml', () {
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

    test('resolution', wrap(() {
      var testDir = path.join(testDirectory, 'data', 'embedder_client');
      new Driver().start([
        '--packages',
        path.join(testDir, '_packages'),
        path.join(testDir, 'embedder_yaml_user.dart')
      ]);

      expect(exitCode, 0);
      expect(outSink.toString(), contains('No issues found'));
    }));

    test('sdk setup', wrap(() {
      var testDir = path.join(testDirectory, 'data', 'embedder_client');
      Driver driver = new Driver();
      driver.start([
        '--packages',
        path.join(testDir, '_packages'),
        path.join(testDir, 'embedder_yaml_user.dart')
      ]);

      DirectoryBasedDartSdk sdk = driver.sdk;
      expect(sdk.useSummary, false);
    }));
  });
}

/// Wrap a function call to dump stdout and stderr in case of an exception.
Function wrap(Function f) {
  return () {
    try {
      f();
    } catch (e) {
      if (outSink.toString().isNotEmpty) {
        print('stdout:');
        print(outSink);
      }
      if (errorSink.toString().isNotEmpty) {
        print('stderr:');
        print(errorSink);
      }
      throw e;
    }
  };
}
