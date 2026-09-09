// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

void main() {
  group('DevToolsUtils', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('devtools_utils_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getVersion returns version from version.json', () async {
      final versionFile = File('${tempDir.path}/version.json');
      await versionFile.writeAsString(jsonEncode({'version': '2.35.0'}));

      final version = await DevToolsUtils.getVersion(tempDir.path);
      expect(version, '2.35.0');
    });

    test('getVersion returns unknown when version.json is missing', () async {
      final version = await DevToolsUtils.getVersion(tempDir.path);
      expect(version, 'unknown');
    });

    test(
      'getVersion returns unknown when version.json is invalid JSON',
      () async {
        final versionFile = File('${tempDir.path}/version.json');
        await versionFile.writeAsString('not-json');

        final version = await DevToolsUtils.getVersion(tempDir.path);
        expect(version, 'unknown');
      },
    );
  });
}
