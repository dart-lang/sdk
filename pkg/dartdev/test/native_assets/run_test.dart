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

  for (final verbose in [true, false]) {
    final testModifier = ['', if (verbose) 'verbose'].join(' ');
    test('dart run$testModifier', timeout: longTimeout, () async {
      await nativeAssetsTest('dart_app', (dartAppUri) async {
        final result = await runDart(
          arguments: [
            '--enable-experiment=native-assets',
            'run',
            if (verbose) '-v',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
        );
        expectDartAppStdout(result.stdout);
        if (verbose) {
          expect(result.stdout, contains('build.dart'));
        } else {
          expect(result.stdout, isNot(contains('build.dart')));
        }
      });
    });
  }

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

  test('dart build native assets disabled', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'run',
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

  test('dart run some_dev_dep', timeout: longTimeout, () async {
    await nativeAssetsTest('native_add', (packageUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'run',
          '-v',
          'some_dev_dep',
        ],
        workingDirectory: packageUri,
        logger: logger,
      );
      // It should not build native_add for running ffigen.
      expect(result.stdout, isNot(contains('build.dart')));
    });
  });

  test('dart link assets succeeds', timeout: longTimeout, () async {
    await nativeAssetsTest('drop_dylib_link', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'run',
          'bin/drop_dylib_link.dart',
          'add'
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(result.exitCode, 0);
    });
  });

  test('dart link assets doesnt have treeshaken asset', timeout: longTimeout,
      () async {
    await nativeAssetsTest('drop_dylib_link', (dartAppUri) async {
      try {
        await runDart(
          arguments: [
            '--enable-experiment=native-assets',
            'run',
            'bin/drop_dylib_link.dart',
            'multiply'
          ],
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
          '--enable-experiment=native-assets',
          'run',
          'bin/add_asset_link.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(result.exitCode, 0);
    });
  });
}
