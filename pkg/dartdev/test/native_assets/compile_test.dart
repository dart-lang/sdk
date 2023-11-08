// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main() async {
  test('dart compile not supported', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'compile',
          'exe',
          'bin/dart_app.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.stderr,
        contains(
          "'dart compile' does currently not support native assets.",
        ),
      );
      expect(result.exitCode, 255);
    });
  });

  test('dart compile native assets build failure', timeout: longTimeout,
      () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final buildDotDart = dartAppUri.resolve('../native_add/build.dart');
      await File.fromUri(buildDotDart).writeAsString('''
void main(List<String> args) {
  throw UnimplementedError();
}
''');
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'compile',
          'exe',
          'bin/dart_app.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.stderr,
        contains(
          'Native assets build failed.',
        ),
      );
      expect(result.exitCode, 255);
    });
  });
}
