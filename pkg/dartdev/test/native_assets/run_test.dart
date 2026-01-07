// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main([List<String> args = const []]) async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    test('dart run', timeout: longTimeout, () async {
      await nativeAssetsTest('dart_app', (dartAppUri) async {
        final result = await runDart(
          arguments: [
            'run',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
          expectExitCodeZero: false,
        );
        expect(result.exitCode, 254);
        expect(
            result.stderr,
            stringContainsInOrder(
              ['Unavailable experiment: native-assets'],
            ));
      });
    });

    return;
  }

  // No --source option, `dart run` from source does not output target program
  // stdout.

  for (final verbose in [true, false]) {
    final testModifier = verbose ? ' verbose' : '';
    test('dart run$testModifier', timeout: longTimeout, () async {
      await nativeAssetsTest('dart_app', (dartAppUri) async {
        final result = await runDart(
          arguments: [
            'run',
            if (verbose) '-v',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
        );
        expect(result.stdout, contains('Running build hooks'));
        expect(result.stdout, isNot(contains('Running link hooks')));
        expectDartAppStdout(result.stdout);
        if (verbose) {
          expect(result.stdout, contains('build.dart'));
        } else {
          expect(result.stdout, isNot(contains('build.dart')));
        }
      });
    });
  }

  test('dart run --verbosity=error', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'run',
          '--verbosity=error',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
      );
      expect(result.stdout, isNot(contains('Running build hooks')));
      expectDartAppStdout(result.stdout);
    });
  });

  test('dart run test/xxx_test.dart', timeout: longTimeout, () async {
    await nativeAssetsTest('native_add', (packageUri) async {
      final result = await runDart(
        arguments: [
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

  for (final subcommand in ['test', 'test/my_test.dart']) {
    test('dart run $subcommand (dev_dependency_with_hook)',
        timeout: longTimeout, () async {
      await nativeAssetsTest('dev_dependency_with_hook', (packageUri) async {
        final result = await runDart(
          arguments: [
            'run',
            subcommand,
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

  test('dart run some_dev_dep', timeout: longTimeout, () async {
    await nativeAssetsTest('native_add', (packageUri) async {
      final result = await runDart(
        arguments: [
          'run',
          '-v',
          'some_dev_dep',
        ],
        workingDirectory: packageUri,
        logger: logger,
      );
      // It should not build native_add for running ffigen.
      expect(result.stdout, isNot(contains('Running build hooks')));
    });
  });

  test('dart link assets succeeds', timeout: longTimeout, () async {
    await nativeAssetsTest('drop_dylib_link', (dartAppUri) async {
      await runDart(
        arguments: ['run', 'bin/drop_dylib_link.dart', 'add'],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );
    });
  });

  test('dart link assets doesnt have treeshaken asset', timeout: longTimeout,
      () async {
    await nativeAssetsTest('drop_dylib_link', (dartAppUri) async {
      try {
        await runDart(
          arguments: ['run', 'bin/drop_dylib_link.dart', 'multiply'],
          workingDirectory: dartAppUri,
          logger: logger,
          expectExitCodeZero: false,
        );
      } catch (e) {
        expect(e, e is ArgumentError);
        expect(
          (e as ArgumentError).message.toString(),
          contains('''
Couldn't resolve native function 'multiply' in 'package:drop_dylib_link/dylib_multiply' : No asset with id 'package:drop_dylib_link/dylib_multiply' found. Available native assets: package:drop_dylib_link/dylib_add.
'''),
        );
      }
    });
  });

  test('dart add asset in linking', timeout: longTimeout, () async {
    await nativeAssetsTest('add_asset_link', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'run',
          'bin/add_asset_link.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.exitCode,
        isNot(0), // Linking is not enabled. The build hook will throw.
      );
    });
  });

  test('dart run with native dynamic linking', timeout: longTimeout, () async {
    await nativeAssetsTest('native_dynamic_linking', (packageUri) async {
      final result = await runDart(
        arguments: [
          'run',
          'bin/native_dynamic_linking.dart',
        ],
        workingDirectory: packageUri,
        logger: logger,
      );
      expect(result.stdout, contains('42'));
    });
  });

  for (final usePubWorkspace in [true, false]) {
    test(
      'dart run with user defines',
      timeout: longTimeout,
      () async {
        await nativeAssetsTest('user_defines', usePubWorkspace: usePubWorkspace,
            (packageUri) async {
          final result = await runDart(
            arguments: [
              'run',
              'bin/user_defines.dart',
            ],
            workingDirectory: packageUri,
            logger: logger,
          );
          expect(result.stdout, contains('Hello world!'));
        });
      },
    );
  }

  // Regression test for Bug: https://github.com/dart-lang/native/issues/2921.
  test(
    'dart run invoking dart run',
    // Windows not supported: https://github.com/dart-lang/native/issues/1534.
    skip: Platform.isWindows,
    timeout: longTimeout,
    () async {
      await nativeAssetsTest('recursive_invocation', (dartAppUri) async {
        final result = await runDart(
          arguments: [
            'run',
            'bin/subprocess.dart',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
        );
        // No crash.
        expect(result.exitCode, equals(0));
      });
    },
  );
}
