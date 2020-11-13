// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

const numRuns = 10;
final script = Platform.script.resolve('smoke.dart').toString();

void main() {
  group(
    'explicit dartdev smoke -',
    () {
      test('dart run smoke.dart', () async {
        for (int i = 1; i <= numRuns; ++i) {
          if (i % 5 == 0) {
            print('Done [$i/$numRuns]');
          }
          final result = await Process.run(
            Platform.executable,
            [
              'run',
              script,
            ],
          );
          expect(result.stderr, isEmpty);
          expect(result.stdout, contains('Smoke test!'));
          expect(result.exitCode, 0);
        }
      });

      // This test forces DDS to spawn in a separate process.
      test('dart run --enable-vm-service smoke.dart', () async {
        for (int i = 1; i <= numRuns; ++i) {
          if (i % 5 == 0) {
            print('Done [$i/$numRuns]');
          }
          final result = await Process.run(
            Platform.executable,
            [
              'run',
              '--enable-vm-service=0',
              script,
            ],
          );
          expect(result.stderr, isEmpty);
          expect(result.stdout, contains('Smoke test!'));
          expect(result.exitCode, 0);
        }
      });

      // This test verifies that an error isn't thrown when a valid experiment
      // is passed.
      // Experiments are lists here:
      // https://github.com/dart-lang/sdk/blob/master/tools/experimental_features.yaml
      test(
          'dart --enable-experiment=variance '
          'run smoke.dart', () async {
        final result = await Process.run(
          Platform.executable,
          [
            '--enable-experiment=variance',
            'run',
            script,
          ],
        );
        expect(result.stderr, isEmpty);
        expect(result.stdout, contains('Smoke test!'));
        expect(result.exitCode, 0);
      });

      // This test verifies that an error is thrown when an invalid experiment
      // is passed.
      test(
          'dart --enable-experiment=invalid-experiment-name '
          'run smoke.dart', () async {
        final result = await Process.run(
          Platform.executable,
          [
            '--enable-experiment=invalid-experiment-name',
            'run',
            script,
          ],
        );
        expect(result.stderr, isNotEmpty);
        expect(result.stdout, isEmpty);
        expect(result.exitCode, 254);
      });
    },
    timeout: Timeout.none,
  );
}
