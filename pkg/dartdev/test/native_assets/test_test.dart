// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main(List<String> args) async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    return;
  }

  // No --source option, `dart run` from source does not output target program
  // stdout.

  for (final package in [
    'native_add',
    'native_add_version_skew',
    'native_dynamic_linking',
    'system_library',
  ]) {
    test('package:$package dart test', timeout: longTimeout, () async {
      await nativeAssetsTest(package, usePubWorkspace: true,
          (packageUri) async {
        final result = await runDart(
          arguments: [
            '--enable-experiment=native-assets',
            'test',
          ],
          workingDirectory: packageUri,
          logger: logger,
        );
        expect(
          result.stdout,
          stringContainsInOrder(
            [
              'All tests passed!',
            ],
          ),
        );
      });
    });
  }

  test('dart run test:test', timeout: longTimeout, () async {
    await nativeAssetsTest('native_add', (packageUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'run',
          'test:test',
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

  test('dart build native assets disabled', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'test',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('Enable native assets'));
      expect(result.stderr, contains('native_add'));
    });
  });

  test('run pub get if needed', timeout: longTimeout, () async {
    await nativeAssetsTest(
      'native_add',
      skipPubGet: true,
      (dartAppUri) async {
        final result = await runDart(
          arguments: [
            'test',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
          expectExitCodeZero: false,
        );
        expect(result.exitCode, isNot(0));
      },
    );
  });

  test('with native dynamic linking', timeout: longTimeout, () async {
    await nativeAssetsTest('native_dynamic_linking', (packageUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'test',
        ],
        workingDirectory: packageUri,
        logger: logger,
      );
      expect(
        result.stdout,
        stringContainsInOrder(
          [
            'invoke native function',
            'All tests passed!',
          ],
        ),
      );
    });
  });

  test(
    'dart test with user defines',
    timeout: longTimeout,
    () async {
      await nativeAssetsTest('user_defines', (packageUri) async {
        final result = await runDart(
          arguments: [
            '--enable-experiment=native-assets',
            'test',
          ],
          workingDirectory: packageUri,
          logger: logger,
        );
        expect(
          result.stdout,
          stringContainsInOrder(
            [
              'All tests passed!',
            ],
          ),
        );
      });
    },
  );
}
