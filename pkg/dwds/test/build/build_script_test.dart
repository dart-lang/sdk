// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dwds/src/handlers/injected_client_js.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_path_utils.dart';

void main() {
  group('Committed file integrity tests', () {
    test('injected_client_js.dart is in sync with web/client.dart', () async {
      final clientDartString = File(
        await dwdsPath('web/client.dart'),
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
      // Use Platform.executable to ensure the same Dart SDK is used. Only
      // resolve the absolute path if it's a local/relative path. Global
      // system commands (no path separators) are passed as-is.
      final executable = Platform.executable;
      final resolvedExecutable = executable.contains(p.separator)
          ? File(executable).absolute.path
          : executable;
      final result = await Process.run(resolvedExecutable, [
        'run',
        'tool/build.dart',
      ], workingDirectory: await dwdsPackageRoot);

      expect(
        result.exitCode,
        0,
        reason: 'Build script failed: ${result.stdout}\n${result.stderr}',
      );
    });

    test('generates client.js', () async {
      final clientJsFile = File(
        await dwdsPath(p.join('lib', 'src', 'injected', 'client.js')),
      );
      expect(clientJsFile.existsSync(), isTrue);
      expect(clientJsFile.lengthSync(), greaterThan(0));
    });

    test('generates version.dart', () async {
      final versionFile = File(
        await dwdsPath(p.join('lib', 'src', 'version.dart')),
      );
      expect(versionFile.existsSync(), isTrue);
      expect(
        versionFile.readAsStringSync(),
        contains('const packageVersion ='),
      );
    });

    test('generates injected_client_js.dart', () async {
      final injectedFile = File(
        await dwdsPath(
          p.join('lib', 'src', 'handlers', 'injected_client_js.dart'),
        ),
      );
      expect(injectedFile.existsSync(), isTrue);
      expect(injectedFile.lengthSync(), greaterThan(0));
    });

    test('injected_client_js.dart matches client.js content', () async {
      final clientJsFile = File(
        await dwdsPath(p.join('lib', 'src', 'injected', 'client.js')),
      );
      final actualClientJs = clientJsFile.readAsStringSync().replaceAll(
        '\r\n',
        '\n',
      );

      final injectedFile = File(
        await dwdsPath(
          p.join('lib', 'src', 'handlers', 'injected_client_js.dart'),
        ),
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
