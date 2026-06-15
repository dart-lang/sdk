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

    test('run command sets DASH__TOOL and DASH__SUPPRESS_ANALYTICS', () async {
      final p = project(
        mainSrc: '''
import 'dart:io';
void main() {
  print('DASH__TOOL: \${Platform.environment['DASH__TOOL']}');
  print('DASH__SUPPRESS_ANALYTICS: '
      '\${Platform.environment['DASH__SUPPRESS_ANALYTICS']}');
}
''',
      );

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', p.relativeFilePath],
        workingDirectory: p.dir.path,
        environment: {
          'PUB_CACHE': p.pubCachePath,
          // Force 'BOT': 'false' to ensure that the test is not affected if the
          // test suite itself is running in a CI / bot environment, which would
          // otherwise implicitly suppress analytics.
          'BOT': 'false',
        },
      );
      expect(result.exitCode, 0);
      expect(result.stdout, contains('DASH__TOOL: dart-tool'));
      expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: false'));
    });

    test('run command preserves existing DASH__TOOL', () async {
      final p = project(
        mainSrc: '''
import 'dart:io';
void main() {
  print('DASH__TOOL: \${Platform.environment['DASH__TOOL']}');
}
''',
      );

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', p.relativeFilePath],
        workingDirectory: p.dir.path,
        environment: {
          'PUB_CACHE': p.pubCachePath,
          'DASH__TOOL': 'flutter-tool',
        },
      );
      expect(result.exitCode, 0);
      expect(result.stdout, contains('DASH__TOOL: flutter-tool'));
    });

    test(
      '--suppress-analytics propagates DASH__SUPPRESS_ANALYTICS=true',
      () async {
        final p = project(
          mainSrc: '''
import 'dart:io';
void main() {
  print('DASH__SUPPRESS_ANALYTICS: '
      '\${Platform.environment['DASH__SUPPRESS_ANALYTICS']}');
}
''',
        );

        final result = await Process.run(
          Platform.resolvedExecutable,
          ['--suppress-analytics', 'run', p.relativeFilePath],
          workingDirectory: p.dir.path,
          environment: {
            'PUB_CACHE': p.pubCachePath,
          },
        );
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: true'));
      },
    );

    test(
      'parent env DASH__SUPPRESS_ANALYTICS=true propagates as true',
      () async {
        final p = project(
          mainSrc: '''
import 'dart:io';
void main() {
  print('DASH__SUPPRESS_ANALYTICS: '
      '\${Platform.environment['DASH__SUPPRESS_ANALYTICS']}');
}
''',
        );

        final result = await Process.run(
          Platform.resolvedExecutable,
          ['run', p.relativeFilePath],
          workingDirectory: p.dir.path,
          environment: {
            'PUB_CACHE': p.pubCachePath,
            'DASH__SUPPRESS_ANALYTICS': 'true',
          },
        );
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: true'));
      },
    );
  });
}
