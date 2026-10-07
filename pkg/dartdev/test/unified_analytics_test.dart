// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/telemetry/project_cache.dart';
import 'package:dartdev/src/unified_analytics.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('collectPubspecTelemetry', () {
    late Directory tempDir;
    late File cacheFile;
    late ProjectTelemetryCache cache;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dartdev_analytics_test_');
      cacheFile = File(path.join(tempDir.path, 'cache.json'));
      cache = ProjectTelemetryCache(cacheFile);
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {
        // Ignore cleanup errors
      }
    });

    void createPackageConfig(
      Directory dir,
      List<Map<String, String>> packages,
    ) {
      final dotDartTool = Directory(path.join(dir.path, '.dart_tool'))
        ..createSync(recursive: true);
      final file = File(path.join(dotDartTool.path, 'package_config.json'));
      file.writeAsStringSync(
        jsonEncode({'configVersion': 2, 'packages': packages}),
      );
    }

    test('returns null when no pubspec.yaml exists in parent hierarchy', () {
      expect(collectPubspecTelemetry(dir: tempDir, cache: cache), isNull);
    });

    test('returns null when package_config.json is missing', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
dependencies:
  path: ^1.8.0
''');

      expect(collectPubspecTelemetry(dir: tempDir, cache: cache), isNull);
    });

    test('finds pubspec.yaml, extracts telemetry, and populates cache', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.5.0
dependencies:
  path: ^1.8.0
''');
      createPackageConfig(tempDir, [
        {
          'name': 'path',
          'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/path-1.8.0',
          'packageUri': 'lib/',
        },
      ]);

      final now = 1752000000;
      final telemetry = collectPubspecTelemetry(
        dir: tempDir,
        cache: cache,
        nowSeconds: now,
      );
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'path'});
      expect(telemetry.hasFlutterSdk, isFalse);
      expect(telemetry.environmentSdk, '^3.5.0');

      // Verify cache hit on second run throttles (returns null) within 24 hours
      final cachedTelemetry = collectPubspecTelemetry(
        dir: tempDir,
        cache: cache,
        nowSeconds: now,
      );
      expect(cachedTelemetry, isNull);

      // Verify telemetry is re-sent after 24 hours have elapsed
      final expiredTelemetry = collectPubspecTelemetry(
        dir: tempDir,
        cache: cache,
        nowSeconds: now + 60 * 60 * 24 + 1,
      );
      expect(expiredTelemetry, isNotNull);

      // Verify telemetry is re-sent when pubspec content changes within 24 hours
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.6.0
dependencies:
  path: ^1.8.0
''');
      final mutatedTelemetry = collectPubspecTelemetry(
        dir: tempDir,
        cache: cache,
        nowSeconds: now + 60 * 60 * 24 + 2,
      );
      expect(mutatedTelemetry, isNotNull);
      expect(mutatedTelemetry!.environmentSdk, '^3.6.0');
    });

    test(
      'finds pubspec from nested subdirectory and shares cache with root',
      () {
        File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.5.0
dependencies:
  path: ^1.8.0
''');
        createPackageConfig(tempDir, [
          {
            'name': 'path',
            'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/path-1.8.0',
            'packageUri': 'lib/',
          },
        ]);

        final nestedDir = Directory(path.join(tempDir.path, 'test', 'unit'))
          ..createSync(recursive: true);

        // Invocation from nested subdirectory resolves root and populates cache
        final nestedTelemetry = collectPubspecTelemetry(
          dir: nestedDir,
          cache: cache,
        );
        expect(nestedTelemetry, isNotNull);
        expect(nestedTelemetry!.publicDependencies, {'path'});
        expect(nestedTelemetry.hasFlutterSdk, isFalse);
        expect(nestedTelemetry.environmentSdk, '^3.5.0');

        // Running from project root hits the exact same cache entry
        final rootTelemetry = collectPubspecTelemetry(
          dir: tempDir,
          cache: cache,
        );
        expect(rootTelemetry, isNull);
      },
    );

    test('fails silently and returns null when pubspec.yaml is malformed', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
dependencies:
  invalid: [yaml: structure
''');
      createPackageConfig(tempDir, [
        {
          'name': 'path',
          'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/path-1.8.0',
          'packageUri': 'lib/',
        },
      ]);

      expect(collectPubspecTelemetry(dir: tempDir, cache: cache), isNull);
    });
  });
}
