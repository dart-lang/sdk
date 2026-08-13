// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'asset_server.dart';
import 'package.dart';

void main() {
  group('AssetServer', () {
    late AssetServer server;
    late Directory tempDir;
    late Directory dartAssetDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('test_server_');
      dartAssetDir = Directory('${tempDir.path}/assets')..createSync();
      File('${dartAssetDir.path}/test.txt').writeAsStringSync('asset content');

      server = await AssetServer.listen(
        printOnFailure: printOnFailure,
        dartAssetPath: dartAssetDir.uri,
        flutterAssetPath: null,
      );
    });

    tearDown(() async {
      await server.close();
      tempDir.deleteSync(recursive: true);
    });

    test('serves dart assets', () async {
      final response = await http.get(server.baseUrl.resolve('dart/test.txt'));
      expect(response.statusCode, 200);
      expect(response.body, 'asset content');
    });

    test('returns 404 for unknown package', () async {
      final response = await http.get(
        server.baseUrl.resolve('api/packages/unknown_pkg'),
      );
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body), {
        'error': {'message': 'Package not found'},
      });
    });

    test('returns 404 for unknown archive', () async {
      final response = await http.get(
        server.baseUrl.resolve('archive/unknown_pkg-1.0.0.tar.gz'),
      );
      expect(response.statusCode, 404);
    });

    test('can add and retrieve a single package version', () async {
      final pkg = await Package.fromFileMap({
        'pubspec.yaml': 'name: foo\nversion: 1.0.0',
        'lib/foo.dart': 'void main() {}',
      });
      server.addPackage(pkg);

      final response = await http.get(
        server.baseUrl.resolve('api/packages/foo'),
      );
      expect(response.statusCode, 200);
      expect(
        response.headers['content-type'],
        contains('application/vnd.pub.v2+json'),
      );

      final body = jsonDecode(response.body) as Map<String, Object?>;
      expect(body['name'], 'foo');
      expect(body['versions'], hasLength(1));

      final latest = body['latest'] as Map<String, Object?>;
      expect(latest['version'], '1.0.0');
      expect(latest['archive_url'], endsWith('/archive/foo-1.0.0.tar.gz'));

      final archiveResponse = await http.get(
        Uri.parse(latest['archive_url'] as String),
      );
      expect(archiveResponse.statusCode, 200);
      expect(
        archiveResponse.headers['content-type'],
        'application/octet-stream',
      );
      // We know fromFileMap creates a valid tar.gz,
      // so we just verify bytes were returned.
      expect(archiveResponse.bodyBytes, isNotEmpty);
    });

    test('correctly sorts versions to find the latest', () async {
      // Add versions out of order
      server.addPackage(
        await Package.fromFileMap({
          'pubspec.yaml': 'name: bar\nversion: 1.0.0',
        }),
      );
      server.addPackage(
        await Package.fromFileMap({
          'pubspec.yaml': 'name: bar\nversion: 2.0.0',
        }),
      );
      server.addPackage(
        await Package.fromFileMap({
          'pubspec.yaml': 'name: bar\nversion: 1.5.0-dev.1',
        }),
      );
      server.addPackage(
        await Package.fromFileMap({
          'pubspec.yaml': 'name: bar\nversion: 0.9.0',
        }),
      );
      server.addPackage(
        await Package.fromFileMap({
          'pubspec.yaml': 'name: bar\nversion: 2.0.1-alpha',
        }),
      );

      final response = await http.get(
        server.baseUrl.resolve('api/packages/bar'),
      );
      expect(response.statusCode, 200);

      final body = jsonDecode(response.body) as Map<String, Object?>;
      expect(body['name'], 'bar');
      expect(body['versions'], hasLength(5));

      // Versions list should be sorted (pub_semver handles the logic)
      final versions = (body['versions'] as List<Object?>)
          .map((v) => (v as Map<String, Object?>)['version'] as String)
          .toList();
      expect(versions, [
        '0.9.0',
        '1.0.0',
        '1.5.0-dev.1',
        '2.0.0',
        '2.0.1-alpha',
      ]);

      // Latest should be the highest version
      final latest = body['latest'] as Map<String, Object?>;
      expect(latest['version'], '2.0.1-alpha');
    });
  });
}
