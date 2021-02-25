// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/server/sdk_configuration.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('SdkConfiguration', () {
    Directory tempDir;

    tearDown(() {
      tempDir?.deleteSync(recursive: true);
    });

    test('readFromSdk', () {
      expect(SdkConfiguration.readFromSdk(), isNotNull);
    });

    test("custom settings file doesn't exist", () {
      tempDir = Directory.systemTemp.createTempSync('SdkConfiguration');
      var file = File(path.join(tempDir.path, 'config.json'));

      expect(() {
        SdkConfiguration.readFromFile(file);
      }, throwsA(TypeMatcher<String>()));
    });

    test('is not configured', () {
      tempDir = Directory.systemTemp.createTempSync('SdkConfiguration');
      var file = File(path.join(tempDir.path, 'config.json'));
      file.writeAsStringSync('''
{}
''');

      var config = SdkConfiguration.readFromFile(file);

      expect(config.hasAnyOverrides, isFalse);
      expect(config.analyticsId, isNull);
      expect(config.analyticsForceEnabled, isNull);
      expect(config.crashReportingId, isNull);
      expect(config.crashReportingForceEnabled, isNull);
    });

    test('is configured', () {
      tempDir = Directory.systemTemp.createTempSync('SdkConfiguration');
      var file = File(path.join(tempDir.path, 'config.json'));
      file.writeAsStringSync('''
{
  "server.analytics.id": "aaaa-1234",
  "server.analytics.forceEnabled": true,

  "server.crash.reporting.id": "Test_crash_id",
  "server.crash.reporting.forceEnabled": true
}
''');

      var config = SdkConfiguration.readFromFile(file);

      expect(config.hasAnyOverrides, isTrue);
      expect(config.analyticsId, 'aaaa-1234');
      expect(config.analyticsForceEnabled, isTrue);
      expect(config.crashReportingId, 'Test_crash_id');
      expect(config.crashReportingForceEnabled, isTrue);
    });
  });
}
