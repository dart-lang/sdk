// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/telemetry/pubspec_scanner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('scanPubspecTelemetry', () {
    late Directory tempDir;
    late Directory originalCurrentDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dartdev_scanner_test_');
      originalCurrentDir = Directory.current;
    });

    tearDown(() {
      Directory.current = originalCurrentDir;
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
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

    test('returns null when no pubspec.yaml exists', () {
      expect(scanPubspecTelemetry(tempDir), isNull);
    });

    test(
      'returns null when pubspec exists but package_config.json is missing (conservative fallback)',
      () {
        File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
dependencies:
  path: ^1.8.0
''');
        expect(scanPubspecTelemetry(tempDir), isNull);
      },
    );

    test('finds pubspec.yaml and package_config.json up to 5 levels deep', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
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

      var deepDir = tempDir;
      for (var i = 0; i < 5; i++) {
        deepDir = Directory(path.join(deepDir.path, 'level_$i'))..createSync();
      }

      final telemetry = scanPubspecTelemetry(deepDir);
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'path'});
      expect(telemetry.hasFlutterSdk, isFalse);
      expect(telemetry.environmentSdk, isNull);
    });

    test('finds pubspec.yaml even > 5 levels deep', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
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

      var deepDir = tempDir;
      for (var i = 0; i < 6; i++) {
        deepDir = Directory(path.join(deepDir.path, 'level_$i'))..createSync();
      }

      final telemetry = scanPubspecTelemetry(deepDir);
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'path'});
    });

    test(
      'strictly strips private workspace packages in a Dart 3.5+ Pub Workspace',
      () {
        // Simulate a workspace root with .dart_tool/package_config.json
        createPackageConfig(tempDir, [
          {
            'name': 'path',
            'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/path-1.8.0',
            'packageUri': 'lib/',
          },
          {
            'name': 'secret_trading_algo',
            'rootUri': '../secret_trading_algo',
            'packageUri': 'lib/',
          },
        ]);

        // Simulate member package inside workspace
        final memberDir = Directory(path.join(tempDir.path, 'pkgs', 'app'))
          ..createSync(recursive: true);
        File(path.join(memberDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: app
resolution: workspace
dependencies:
  path: ^1.8.0
  secret_trading_algo:
''');

        final telemetry = scanPubspecTelemetry(memberDir);
        expect(telemetry, isNotNull);
        // 'path' is kept because rootUri is hosted on pub.dev
        // 'secret_trading_algo' is stripped because rootUri is a relative workspace path!
        expect(telemetry!.publicDependencies, {'path'});
        expect(telemetry.hasFlutterSdk, isFalse);
      },
    );

    test('extracts both dependencies and dev_dependencies', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
dependencies:
  path: ^1.8.0
dev_dependencies:
  test: ^1.24.0
  lints: ^3.0.0
''');
      createPackageConfig(tempDir, [
        {
          'name': 'path',
          'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/path-1.8.0',
          'packageUri': 'lib/',
        },
        {
          'name': 'test',
          'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/test-1.24.0',
          'packageUri': 'lib/',
        },
        {
          'name': 'lints',
          'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/lints-3.0.0',
          'packageUri': 'lib/',
        },
      ]);

      final telemetry = scanPubspecTelemetry(tempDir);
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'path', 'test', 'lints'});
      expect(telemetry.hasFlutterSdk, isFalse);
    });

    test('detects Flutter SDK in environment', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.5.0
  flutter: '>=3.0.0'
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

      final telemetry = scanPubspecTelemetry(tempDir);
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'path'});
      expect(telemetry.hasFlutterSdk, isTrue);
      expect(telemetry.environmentSdk, '^3.5.0');
    });

    test('detects Flutter SDK in dependencies', () {
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.5.0
dependencies:
  path: ^1.8.0
  flutter:
    sdk: flutter
''');
      createPackageConfig(tempDir, [
        {
          'name': 'path',
          'rootUri': 'file:///home/user/.pub-cache/hosted/pub.dev/path-1.8.0',
          'packageUri': 'lib/',
        },
      ]);

      final telemetry = scanPubspecTelemetry(tempDir);
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'path'});
      expect(telemetry.hasFlutterSdk, isTrue);
      expect(telemetry.environmentSdk, '^3.5.0');
    });

    test('extracts and truncates long sdk constraint', () {
      final longSdk = '^3.0.0 ${'a' * 110}';
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: "$longSdk"
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

      final telemetry = scanPubspecTelemetry(tempDir);
      expect(telemetry, isNotNull);
      expect(telemetry!.environmentSdk!.length, 100);
      expect(telemetry.environmentSdk, longSdk.substring(0, 100));
    });

    test('supports custom PUB_CACHE environment variable', () {
      final customCacheDir = Directory(
        path.join(tempDir.path, 'my_custom_cache'),
      )..createSync(recursive: true);
      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.5.0
dependencies:
  shelf: ^1.4.0
  fake_hosted: ^1.0.0
''');
      createPackageConfig(tempDir, [
        {
          'name': 'shelf',
          'rootUri': path
              .toUri(
                path.join(
                  customCacheDir.path,
                  'hosted',
                  'pub.dev',
                  'shelf-1.4.0',
                ),
              )
              .toString(),
          'packageUri': 'lib/',
        },
        {
          'name': 'fake_hosted',
          'rootUri': path
              .toUri(
                path.join(
                  tempDir.path,
                  'not_in_cache',
                  'hosted',
                  'pub.dev',
                  'fake_hosted-1.0.0',
                ),
              )
              .toString(),
          'packageUri': 'lib/',
        },
      ]);

      final telemetry = scanPubspecTelemetry(
        tempDir,
        environment: {'PUB_CACHE': customCacheDir.path},
      );
      expect(telemetry, isNotNull);
      expect(telemetry!.publicDependencies, {'shelf'});
    });
  });

  group('findPubspecFile', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'dartdev_find_pubspec_test_',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('returns null when no pubspec exists', () {
      expect(findPubspecFile(tempDir), isNull);
    });

    test('finds pubspec.yaml in current directory', () {
      final pubspec = File(path.join(tempDir.path, 'pubspec.yaml'))
        ..writeAsStringSync('name: test_pkg\n');
      final found = findPubspecFile(tempDir);
      expect(found, isNotNull);
      expect(found!.path, pubspec.path);
    });

    test('finds pubspec.yaml in deeply nested directory', () {
      final pubspec = File(path.join(tempDir.path, 'pubspec.yaml'))
        ..writeAsStringSync('name: test_pkg\n');
      final nestedDir = Directory(
        path.join(
          tempDir.path,
          'level1',
          'level2',
          'level3',
          'level4',
          'l5',
          'l6',
          'l7',
        ),
      )..createSync(recursive: true);

      final found = findPubspecFile(nestedDir);
      expect(found, isNotNull);
      expect(found!.path, pubspec.path);
    });
  });
}
