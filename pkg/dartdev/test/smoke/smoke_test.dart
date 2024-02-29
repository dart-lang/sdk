// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

const numRuns = 10;

final smokeTestScript = r'''
void main() {
  print('Smoke test!');
}
''';

final observeSmokeTestScript = r'''
void main() async {
  print('Observe smoke test!');
  int i = 0;
  while(true) {
    await Future.delayed(Duration(milliseconds: 10));
    i++;
  }
}
''';

final dartVMServiceMsg =
    'The Dart VM service is listening on http://127.0.0.1:';

void main() {
  group(
    'explicit dartdev smoke -',
    () {
      late final String script;
      late final String observeScript;
      late TestProject p;
      late TestProject op;

      setUpAll(() {
        p = project(mainSrc: smokeTestScript);
        script = path.join(p.dirPath, p.relativeFilePath);
        op = project(mainSrc: observeSmokeTestScript);
        observeScript = path.join(op.dirPath, op.relativeFilePath);
      });

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
          bool sawProgramMsg = false;
          bool sawServiceMsg = false;
          void onData(event) {
            if (event.contains(dartVMServiceMsg)) {
              sawServiceMsg = true;
            } else if (event.contains('Observe smoke test!')) {
              sawProgramMsg = true;
            }
            if (sawServiceMsg && sawProgramMsg) {
              op.kill();
            }
          }

          await op.runWithVmService([
            'run',
            '--enable-vm-service=0',
            op.relativeFilePath,
          ], onData);
          expect(sawServiceMsg, true);
          expect(sawProgramMsg, true);
        }
      });

      test('dart run --enable-vm-service smoke.dart with used port', () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final process = await Process.start(
          Platform.executable,
          [
            'run',
            '--enable-vm-service=${server.port}',
            observeScript,
          ],
        );
        final completer = Completer<void>();
        late StreamSubscription sub;
        bool sawServiceMsg = false;
        void onData(event) {
          print(event);
          if (event.contains('Could not start the VM service:')) {
            sawServiceMsg = true;
            process.kill();
          }
        }

        void onError(error) async {
          process.kill();
          await sub.cancel();
          completer.complete();
        }

        void onDone() async {
          await sub.cancel();
          completer.complete();
        }

        sub = process.stderr
            .transform(utf8.decoder)
            .listen(onData, onError: onError, onDone: onDone);

        // Wait for process to start.
        await completer.future;
        await server.close(force: true);
        expect(sawServiceMsg, true);
      });

      // This test verifies that an error isn't thrown when a valid experiment
      // is passed.
      // Experiments are lists here:
      // https://github.com/dart-lang/sdk/blob/main/tools/experimental_features.yaml
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
