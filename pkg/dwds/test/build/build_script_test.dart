// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dwds/src/handlers/injected_client_js.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Committed file integrity tests', () {
    test('injected_client_js.dart is in sync with web/client.dart', () {
      final clientDartString = File(
        'web/client.dart',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      final expectedHash = sha256
          .convert(utf8.encode(clientDartString))
          .toString();

      expect(
        clientDartHash,
        equals(expectedHash),
        reason:
            'The hash of web/client.dart does not match clientDartHash '
            'in injected_client_js.dart. '
            'Please run `dart run tool/build.dart` to regenerate the asset.',
      );
    });

    test('injected_client_js.dart has normalized line endings', () {
      expect(injectedClientJs.contains('\r'), isFalse);
    });
  });

  group('Build script tests', () {
    setUpAll(() async {
      // Use Platform.executable to ensure we use the same Dart SDK
      final result = await Process.run(Platform.executable, [
        'run',
        'tool/build.dart',
      ]);

      expect(
        result.exitCode,
        0,
        reason: 'Build script failed: ${result.stdout}\n${result.stderr}',
      );
    });

    test('generates client.js', () {
      final clientJsFile = File(p.join('lib', 'src', 'injected', 'client.js'));
      expect(clientJsFile.existsSync(), isTrue);
      expect(clientJsFile.lengthSync(), greaterThan(0));
    });

    test('generates version.dart', () {
      final versionFile = File(p.join('lib', 'src', 'version.dart'));
      expect(versionFile.existsSync(), isTrue);
      expect(
        versionFile.readAsStringSync(),
        contains('const packageVersion ='),
      );
    });

    test('generates injected_client_js.dart', () {
      final injectedFile = File(
        p.join('lib', 'src', 'handlers', 'injected_client_js.dart'),
      );
      expect(injectedFile.existsSync(), isTrue);
      expect(injectedFile.lengthSync(), greaterThan(0));
    });

    test('injected_client_js.dart matches client.js content', () {
      final clientJsFile = File(p.join('lib', 'src', 'injected', 'client.js'));
      final actualClientJs = clientJsFile.readAsStringSync().replaceAll(
        '\r\n',
        '\n',
      );

      final injectedFile = File(
        p.join('lib', 'src', 'handlers', 'injected_client_js.dart'),
      );
      final injectedContent = injectedFile.readAsStringSync();

      final lines = actualClientJs.split('\n');
      final expectedSafeDartString = [
        for (var i = 0; i < lines.length; i++)
          jsonEncode(
            i == lines.length - 1 ? lines[i] : '${lines[i]}\n',
          ).replaceAll(r'$', r'\$'),
      ].join('\n');

      expect(
        injectedContent,
        contains('const injectedClientJs = $expectedSafeDartString;'),
      );
    });
  });
}
