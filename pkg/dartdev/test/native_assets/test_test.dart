// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main([List<String> args = const []]) async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    return;
  }

  // No --source option, `dart run` from source does not output target program
  // stdout.

  for (final package in [
    'dev_dependency_with_hook',
    'native_add_version_skew',
    'native_add',
    'native_dynamic_linking',
    'system_library',
  ]) {
    test('package:$package dart test', timeout: longTimeout, () async {
      await nativeAssetsTest(package, usePubWorkspace: true,
          (packageUri) async {
        final result = await runDart(
          arguments: [
            'test',
          ],
          workingDirectory: packageUri,
          logger: logger,
        );
        expect(result.stdout, contains('Running build hooks'));
        expect(result.stdout, isNot(contains('Running link hooks')));
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

  for (final compiler in ['kernel', 'cli']) {
    test('dart run test:test', timeout: longTimeout, () async {
      await nativeAssetsTest('native_add', (packageUri) async {
        final result = await runDart(
          arguments: [
            'run',
            'test:test',
            '--compiler',
            compiler,
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

  test('run pub get if needed', timeout: longTimeout, () async {
    await nativeAssetsTest(
      'native_add',
      (dartAppUri) async {
        final result = await runDart(
          arguments: [
            'test',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
        );
        expect(result.exitCode, equals(0));
      },
    );
  });

  test('with native dynamic linking', timeout: longTimeout, () async {
    await nativeAssetsTest('native_dynamic_linking', (packageUri) async {
      final result = await runDart(
        arguments: [
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

  for (final compiler in ['kernel', 'cli']) {
    for (final usePubWorkspace in [true, false]) {
      test(
        'dart test with user defines',
        timeout: longTimeout,
        () async {
          await nativeAssetsTest('user_defines',
              usePubWorkspace: usePubWorkspace, (packageUri) async {
            final result = await runDart(
              arguments: [
                'test',
                '--compiler',
                compiler,
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
  }

  test('package:treeshaking_dylib_record_use dart test', timeout: longTimeout,
      () async {
    await nativeAssetsTest('treeshaking_dylib_record_use',
        usePubWorkspace: true, (packageUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=record-use',
          'test',
          '--compiler',
          'cli',
        ],
        workingDirectory: packageUri,
        logger: logger,
      );
      expect(result.stdout, contains('Running build hooks'));
      expect(
        result.stdout,
        anyOf(
          contains('All tests passed!'),
          // TODO(https://github.com/dart-lang/sdk/issues/63295): Use
          // DynamicLibrary.openAsset when available.
          contains('All tests skipped.'),
        ),
      );
    });
  });
}
