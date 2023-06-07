// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main(List<String> args) async {
  final bool fromDartdevSource = args.contains('--source');

  test('dart build', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          if (fromDartdevSource)
            Platform.script.resolve('../../bin/dartdev.dart').toFilePath(),
          'build',
          'bin/dart_app.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
      );

      final exeUri = dartAppUri.resolve('bin/dart_app/dart_app.exe');
      expect(await File.fromUri(exeUri).exists(), true);
      final result = await runProcess(
        executable: exeUri,
        arguments: [],
        workingDirectory: dartAppUri,
        logger: logger,
      );
      expectDartAppStdout(result.stdout);
    });
  });
}
