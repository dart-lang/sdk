// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main(List<String> args) async {
  // No --source option, `dart run` from source does not output target program
  // stdout.

  test('dart run ', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'run',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
      );
      expectDartAppStdout(result.stdout);
    });
  });

  test('dart run test/xxx_test.dart', timeout: longTimeout, () async {
    await nativeAssetsTest('native_add', (packageUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'run',
          'test/native_add_test.dart',
        ],
        workingDirectory: packageUri,
        logger: logger,
      );
      expect(
        result.stdout,
        stringContainsInOrder(
          [
            'native add test',
            'All tests passed!',
          ],
        ),
      );
    });
  });
}
