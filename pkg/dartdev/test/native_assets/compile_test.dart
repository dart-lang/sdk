// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main() async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    return;
  }

  test('dart compile not supported', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
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
          "'dart compile' does not support build hooks, use 'dart build' instead.",
        ),
      );
      expect(result.exitCode, 255);
    });
  });
}
