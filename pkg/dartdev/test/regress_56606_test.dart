// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'utils.dart';

const numRuns = 10;

final smokeTestScript = r'''
void main() {
  print('Smoke test!');
}
''';

void main() {
  late final String script;
  late final TestProject p;

  setUp(() {
    p = project(mainSrc: smokeTestScript);
    script = path.join(p.dirPath, p.relativeFilePath);
  });

  tearDown(() async {
    await p.dispose();
  });

  test(
    'Regression test for https://github.com/dart-lang/sdk/issues/56606',
    () async {
      // Tests for a race condition in the VM service startup / shutdown logic
      // that previously caused crashes when the VM service was enabled for
      // programs with short lifespans.
      for (int i = 1; i <= numRuns; ++i) {
        if (i % 5 == 0) {
          print('Done [$i/$numRuns]');
        }
        final result = await Process.run(
          Platform.executable,
          ['--enable-vm-service', script],
          environment: {'BOT': '1'},
        );
        expect(result.stderr, isEmpty);
        expect(result.stdout, contains('Smoke test!'));
        expect(result.exitCode, 0);
      }
    },
  );
}
