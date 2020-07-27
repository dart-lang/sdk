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
          expect(result.exitCode, 0);
          expect(result.stdout, contains('Smoke test!'));
          expect(result.stderr, isEmpty);
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
          expect(result.exitCode, 0);
          expect(result.stdout, contains('Smoke test!'));
          expect(result.stderr, isEmpty);
        }
      });
    },
    timeout: Timeout.none,
  );
}
