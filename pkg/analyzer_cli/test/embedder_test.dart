// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer_cli/src/driver.dart' show Driver, errorSink, outSink;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('_embedder.yaml', () {
    StringSink savedOutSink, savedErrorSink;
    int savedExitCode;

    setUp(() {
      savedOutSink = outSink;
      savedErrorSink = errorSink;
      savedExitCode = exitCode;
      outSink = StringBuffer();
      errorSink = StringBuffer();
    });

    tearDown(() {
      outSink = savedOutSink;
      errorSink = savedErrorSink;
      exitCode = savedExitCode;
    });

    test('resolution', wrap(() async {
      var testDir = path.join(testDirectory, 'data', 'embedder_client');
      await Driver().start([
        '--packages',
        path.join(testDir, '_packages'),
        path.join(testDir, 'embedder_yaml_user.dart')
      ]);

      expect(exitCode, 0);
      expect(outSink.toString(), contains('No issues found'));
    }));

    test('sdk setup', wrap(() async {
      var testDir = path.join(testDirectory, 'data', 'embedder_client');
      var driver = Driver();
      await driver.start([
        '--packages',
        path.join(testDir, '_packages'),
        path.join(testDir, 'embedder_yaml_user.dart')
      ]);

      var sdk = driver.sdk;
      expect(sdk, const TypeMatcher<FolderBasedDartSdk>());
    }));
  });
}

/// Wrap a function call to dump stdout and stderr in case of an exception.
dynamic Function() wrap(dynamic Function() f) {
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
