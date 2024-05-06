// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    'implicit dartdev smoke -',
    () {
      late final String script;
      late TestProject p;
      late TestProject op;

      setUpAll(() {
        p = project(mainSrc: smokeTestScript);
        script = path.join(p.dirPath, p.relativeFilePath);
        op = project(mainSrc: observeSmokeTestScript);
      });

      test('dart smoke.dart', () async {
        for (int i = 1; i <= numRuns; ++i) {
          if (i % 5 == 0) {
            print('Done [$i/$numRuns]');
          }
          final result = await Process.run(
            Platform.executable,
            [
              script,
            ],
          );
          expect(result.stderr, isEmpty);
          expect(result.stdout, contains('Smoke test!'));
          expect(result.exitCode, 0);
        }
      });

      // This test forces dartdev to run implicitly and for
      // DDS to spawn in a separate process.
      test('dart --enable-vm-service smoke.dart', () async {
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
            '--enable-vm-service=0',
            op.relativeFilePath,
          ], onData);
          expect(sawServiceMsg, true);
          expect(sawProgramMsg, true);
        }
      });
    },
    timeout: Timeout.none,
  );
}
