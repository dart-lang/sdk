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
  for (final verbose in [true, false]) {
    final testModifier = ['', if (verbose) 'verbose'].join(' ');
    test('dart build$testModifier', timeout: longTimeout, () async {
      await nativeAssetsTest('dart_app', (dartAppUri) async {
        final result = await runDart(
          arguments: [
            '--enable-experiment=native-assets',
            if (fromDartdevSource)
              Platform.script.resolve('../../bin/dartdev.dart').toFilePath(),
            'build',
            if (verbose) '-v',
            'bin/dart_app.dart',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
        );
        if (verbose) {
          expect(result.stdout, contains('build.dart'));
        } else {
          expect(result.stdout, isNot(contains('build.dart')));
        }

        final relativeExeUri = Uri.file('./bin/dart_app/dart_app.exe');
        final absoluteExeUri = dartAppUri.resolveUri(relativeExeUri);
        expect(await File.fromUri(absoluteExeUri).exists(), true);
        for (final exeUri in [absoluteExeUri, relativeExeUri]) {
          final result = await runProcess(
            executable: exeUri,
            arguments: [],
            workingDirectory: dartAppUri,
            logger: logger,
          );
          expectDartAppStdout(result.stdout);
        }
      });
    });
  }
}
