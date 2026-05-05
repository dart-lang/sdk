// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/sdk.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  ensureRunFromSdkBinDart();

  group('Environment modification', () {
    test('run command sets DART_ROOT', () async {
      final p = project(
        mainSrc: '''
import 'dart:io';
void main() {
  print('DART_ROOT: \${Platform.environment['DART_ROOT']}');
}
''',
      );

      final result = await p.run(['run', p.relativeFilePath]);
      expect(result.exitCode, 0);
      // The environment variable was set in the parent isolate (dartdev)
      // via VmInteropHandler.setEnvironmentVariable before the run command
      // spawned the new isolate.
      expect(result.stdout, contains('DART_ROOT: ${sdk.sdkPath}'));
    });

    test('run command does not overwrite existing DART_ROOT', () async {
      final p = project(
        mainSrc: '''
import 'dart:io';
void main() {
  print('DART_ROOT: \${Platform.environment['DART_ROOT']}');
}
''',
      );

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', p.relativeFilePath],
        workingDirectory: p.dir.path,
        environment: {
          'PUB_CACHE': p.pubCachePath,
          'DART_ROOT': 'original_value',
        },
      );
      expect(result.exitCode, 0);
      // The environment variable was already set to 'original_value',
      // so dartdev should not overwrite it.
      expect(result.stdout, contains('DART_ROOT: original_value'));
    });
  });
}
