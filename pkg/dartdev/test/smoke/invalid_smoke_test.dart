// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

const numRuns = 10;
final script = Platform.script.resolve('smoke.dart').toString();

void main() {
  group(
    'implicit dartdev smoke -',
    () {
      test('dart invalid.dart', () async {
        for (int i = 1; i <= numRuns; ++i) {
          if (i % 5 == 0) {
            print('Done [$i/$numRuns]');
          }
          final result = await Process.run(
            Platform.executable,
            [
              'invalid.dart',
            ],
          );
          expect(result.exitCode, 64);
          expect(result.stdout, isEmpty);
          expect(
            result.stderr,
            contains(
              'Error when reading \'invalid.dart\':'
              ' No such file or directory',
            ),
          );
        }
      });

      // This test forces dartdev to run implicitly and for
      // DDS to spawn in a separate process..
      test('dart --enable-vm-service invalid.dart', () async {
        for (int i = 1; i <= numRuns; ++i) {
          if (i % 5 == 0) {
            print('Done [$i/$numRuns]');
          }
          final result = await Process.run(
            Platform.executable,
            [
              '--enable-vm-service=0',
              'invalid.dart',
            ],
          );
          expect(result.exitCode, 64);
          expect(result.stdout, contains('Observatory listening'));
          expect(
            result.stderr,
            contains(
              'Error when reading \'invalid.dart\':'
              ' No such file or directory',
            ),
          );
        }
      });

      test('dart run invalid.dart', () async {
        for (int i = 1; i <= numRuns; ++i) {
          if (i % 5 == 0) {
            print('Done [$i/$numRuns]');
          }
          final result = await Process.run(
            Platform.executable,
            [
              'run',
              'invalid.dart',
            ],
          );
          expect(result.exitCode, 254);
          expect(result.stdout, isEmpty);
          expect(
            result.stderr,
            contains(
              'Error when reading \'invalid.dart\':'
              ' No such file or directory',
            ),
          );
        }
      });

      // This test forces DDS to spawn in a separate process.
      test('dart run --enable-vm-service invalid.dart', () async {
        for (int i = 1; i <= numRuns; ++i) {
          if (i % 5 == 0) {
            print('Done [$i/$numRuns]');
          }
          final result = await Process.run(
            Platform.executable,
            [
              'run',
              '--enable-vm-service=0',
              'invalid.dart',
            ],
          );
          expect(result.exitCode, 254);
          expect(result.stdout, contains('Observatory listening'));
          expect(
            result.stderr,
            contains(
              'Error when reading \'invalid.dart\':'
              ' No such file or directory',
            ),
          );
        }
      });
    },
    timeout: Timeout.none,
    // TODO(bkonyi): Fails consistently on bots, need to investigate.
    skip: true,
  );
}
