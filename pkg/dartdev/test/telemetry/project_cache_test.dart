// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/telemetry/project_cache.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('ProjectTelemetryCache', () {
    late Directory tempDir;
    late File cacheFile;
    late ProjectTelemetryCache cache;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dartdev_cache_test_');
      cacheFile = File(path.join(tempDir.path, 'project_telemetry_cache.json'));
      cache = ProjectTelemetryCache(cacheFile);
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('returns null on cache miss when file does not exist', () {
      expect(cache.getEntry('/path/to/project'), isNull);
    });

    test('stores and retrieves telemetry', () {
      final now = 1752000000;
      final telemetry = (
        publicDependencies: {'path', 'test'},
        hasFlutterSdk: false,
        environmentSdk: '^3.0.0',
      );

      cache.set(
        '/path/to/project',
        telemetry,
        contentHash: 'hashx',
        nowSeconds: now,
      );
      expect(cacheFile.existsSync(), isTrue);

      // Verify anonymity: check that plaintext path is NOT in cache file
      final content = cacheFile.readAsStringSync();
      expect(content.contains('/path/to/project'), isFalse);

      final retrieved = cache.getEntry(
        '/path/to/project',
      );
      expect(retrieved, isNotNull);
      expect(retrieved!.publicDependencies, {'path', 'test'});
      expect(retrieved.hasFlutterSdk, isFalse);
      expect(retrieved.environmentSdk, '^3.0.0');
      expect(retrieved.contentHash, 'hashx');
      expect(retrieved.lastSentSeconds, now);
    });

    test('enforces 100-project LRU eviction cap', () {
      final now = 1752000000;

      // Add 105 distinct projects with sequential timestamps
      for (var i = 0; i < 105; i++) {
        cache.set(
          '/path/to/project_$i',
          (
            publicDependencies: {'pkg_$i'},
            hasFlutterSdk: false,
            environmentSdk: null,
          ),
          contentHash: 'hashx_$i',
          nowSeconds: now + i,
        );
      }

      final content = cacheFile.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final projects = json['projects'] as Map<String, dynamic>;

      // Ensure exactly 100 projects remain
      expect(projects.length, 100);

      // The oldest 5 projects (project_0 through project_4) should have been evicted
      for (var i = 0; i < 5; i++) {
        expect(cache.getEntry('/path/to/project_$i'), isNull);
      }

      // The remaining 100 projects (project_5 through project_104) should be valid
      for (var i = 5; i < 105; i++) {
        final res = cache.getEntry('/path/to/project_$i');
        expect(res, isNotNull);
        expect(res!.publicDependencies, {'pkg_$i'});
        expect(res.contentHash, 'hashx_$i');
      }
    });

    test('fails silently and returns null on corrupted JSON cache file', () {
      cacheFile.writeAsStringSync('{ corrupted json: [');
      expect(cache.getEntry('/path/to/project'), isNull);

      // Setting new data over a corrupted file should recover cleanly without crashing
      final telemetry = (
        publicDependencies: {'path'},
        hasFlutterSdk: false,
        environmentSdk: null,
      );
      expect(
        () => cache.set('/path/to/project', telemetry, contentHash: 'hash'),
        returnsNormally,
      );
      expect(cache.getEntry('/path/to/project'), isNotNull);
    });
  });
}
