// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer_cli/src/driver.dart' show Driver, errorSink, outSink;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

main() {
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

    test('resolution', wrap(() async {
      var testDir = path.join(testDirectory, 'data', 'embedder_client');
      await new Driver(isTesting: true).start([
        '--packages',
        path.join(testDir, '_packages'),
        path.join(testDir, 'embedder_yaml_user.dart')
      ]);

      expect(exitCode, 0);
      expect(outSink.toString(), contains('No issues found'));
    }));

    test('sdk setup', wrap(() async {
      var testDir = path.join(testDirectory, 'data', 'embedder_client');
      Driver driver = new Driver(isTesting: true);
      await driver.start([
        '--packages',
        path.join(testDir, '_packages'),
        path.join(testDir, 'embedder_yaml_user.dart')
      ]);

      DartSdk sdk = driver.sdk;
      expect(sdk, new isInstanceOf<FolderBasedDartSdk>());
      expect((sdk as FolderBasedDartSdk).useSummary, isFalse);
    }));
  });
}

/// Wrap a function call to dump stdout and stderr in case of an exception.
Function wrap(Function f) {
  return () async {
    try {
      await f();
    } catch (e) {
      if (outSink.toString().isNotEmpty) {
        print('stdout:');
        print(outSink);
      }
      if (errorSink.toString().isNotEmpty) {
        print('stderr:');
        print(errorSink);
      }
      rethrow;
    }
  };
}
