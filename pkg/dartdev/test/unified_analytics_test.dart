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

      final telemetry = collectPubspecTelemetry(dir: tempDir, cache: cache);
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'path'});
      expect(telemetry.hasFlutterSdk, isFalse);
      expect(telemetry.environmentSdk, '^3.5.0');

      // Verify cache hit on second run without rescanning
      final cachedTelemetry = collectPubspecTelemetry(
        dir: tempDir,
        cache: cache,
      );
      expect(cachedTelemetry, isNotNull);
      expect(cachedTelemetry!.publicDependencies, {'path'});
      expect(cachedTelemetry.hasFlutterSdk, isFalse);
      expect(cachedTelemetry.environmentSdk, '^3.5.0');
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
        expect(rootTelemetry, isNotNull);
        expect(rootTelemetry!.publicDependencies, {'path'});
        expect(rootTelemetry.hasFlutterSdk, isFalse);
        expect(rootTelemetry.environmentSdk, '^3.5.0');
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
