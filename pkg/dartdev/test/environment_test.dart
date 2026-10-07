// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/sdk.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'utils.dart';

/// The location of the unified_analytics config file under [home].
String _configPath(String home) =>
    path.join(home, '.dart-tool', 'dart-flutter-telemetry.config');

/// Creates an isolated home directory for running `dart`, so tests don't
/// depend on (or modify) the analytics state of the machine running them.
///
/// Returns the home directory path and an environment that points at it.
///
/// If [consented] is true, the home directory's analytics config records that
/// the Dart CLI has already shown its consent message. Otherwise the home
/// directory is empty, which `dart` treats as a first run.
///
/// The parent environment is not inherited (use `includeParentEnvironment:
/// false`), so a `DASH__SUPPRESS_ANALYTICS` or bot variable set for the test
/// process doesn't leak in. `BOT` is forced to `false` so that a CI
/// environment doesn't implicitly suppress analytics; pass `'BOT': null` in
/// [extra] to leave it unset.
({Map<String, String> env, String home}) _setUpIsolatedHome(
  TestProject p, {
  required bool consented,
  Map<String, String?> extra = const {},
}) {
  final home = path.join(p.root.path, 'home');
  Directory(home).createSync(recursive: true);
  if (consented) {
    File(_configPath(home))
      ..createSync(recursive: true)
      ..writeAsStringSync('reporting=1\ndart-tool=2026-01-01,1\n');
  }

  final env = <String, String?>{
    'PUB_CACHE': p.pubCachePath,
    'BOT': 'false',
    'PATH': Platform.environment['PATH'] ?? '',
    if (Platform.isWindows) ...{
      'SystemRoot': Platform.environment['SystemRoot'],
      'TEMP': Platform.environment['TEMP'],
      'LOCALAPPDATA': Platform.environment['LOCALAPPDATA'],
      'USERPROFILE': Platform.environment['USERPROFILE'],
      'SystemDrive': Platform.environment['SystemDrive'],
      'APPDATA': home,
    },
    if (Platform.isMacOS || Platform.isLinux) 'HOME': home,
    ...extra,
  };
  return (
    env: {for (final MapEntry(:key, :value) in env.entries) key: ?value},
    home: home,
  );
}

/// Source for a script that prints the analytics variables it inherited.
const _printAnalyticsEnvSrc = '''
import 'dart:io';
void main() {
  print('DASH__TOOL: \${Platform.environment['DASH__TOOL']}');
  print('DASH__SUPPRESS_ANALYTICS: '
      '\${Platform.environment['DASH__SUPPRESS_ANALYTICS']}');
  print('DART_ROOT: \${Platform.environment['DART_ROOT']}');
}
''';

/// Creates a project with an executable that prints the analytics variables
/// it inherited, for use with `dart run <name>@{path: ...}`.
TestProject _executableProject() {
  final p = project();
  p.file(
    'pubspec.yaml',
    'name: ${p.name}\nenvironment:\n  sdk: ^3.0.0\nexecutables:\n  ${p.name}:\n',
  );
  p.file('bin/${p.name}.dart', _printAnalyticsEnvSrc);
  return p;
}

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
      final p = project(mainSrc: _printAnalyticsEnvSrc);

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', p.relativeFilePath],
        workingDirectory: p.dir.path,
        includeParentEnvironment: false,
        // Use a home directory where the consent message has already been
        // shown, so the result doesn't depend on the machine's analytics
        // state.
        environment: _setUpIsolatedHome(p, consented: true).env,
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
        final p = project(mainSrc: _printAnalyticsEnvSrc);

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
        final p = project(mainSrc: _printAnalyticsEnvSrc);

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

    test(
      'run command with @ descriptor sets DASH__TOOL, DASH__SUPPRESS_ANALYTICS, and DART_ROOT',
      () async {
        final p = _executableProject();

        final result = await Process.run(
          Platform.resolvedExecutable,
          ['run', '${p.name}@{path: ${p.dir.path}}'],
          workingDirectory: p.dir.path,
          includeParentEnvironment: false,
          environment: _setUpIsolatedHome(p, consented: true).env,
        );
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__TOOL: dart-tool'));
        expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: false'));
        expect(result.stdout, contains('DART_ROOT: ${sdk.sdkPath}'));
      },
    );

    test(
      'run command with @ descriptor preserves existing DASH__TOOL',
      () async {
        final p = _executableProject();

        final result = await Process.run(
          Platform.resolvedExecutable,
          ['run', '${p.name}@{path: ${p.dir.path}}'],
          workingDirectory: p.dir.path,
          includeParentEnvironment: false,
          environment: _setUpIsolatedHome(
            p,
            consented: true,
            extra: {'BOT': null, 'DASH__TOOL': 'flutter-tool'},
          ).env,
        );
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__TOOL: flutter-tool'));
      },
    );

    test(
      'run command with @ descriptor and --suppress-analytics propagates DASH__SUPPRESS_ANALYTICS=true',
      () async {
        final p = _executableProject();

        final result = await Process.run(
          Platform.resolvedExecutable,
          ['--suppress-analytics', 'run', '${p.name}@{path: ${p.dir.path}}'],
          workingDirectory: p.dir.path,
          includeParentEnvironment: false,
          environment: _setUpIsolatedHome(
            p,
            consented: true,
            extra: {'BOT': null},
          ).env,
        );
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: true'));
      },
    );
  });

  // `Process.run` gives `dart` no terminal, so the consent message is never
  // printed. Consent stays pending, nothing is recorded, and sub-tools are
  // not suppressed. (The terminal case, where sub-tools are suppressed, is
  // covered by unit tests in analytics_test.dart.)
  group(
    'First run without a terminal',
    () {
      Future<ProcessResult> runWith(
        TestProject p,
        Map<String, String> env, {
        List<String> dartArgs = const [],
      }) => Process.run(
        Platform.resolvedExecutable,
        [...dartArgs, 'run', p.relativeFilePath],
        workingDirectory: p.dir.path,
        includeParentEnvironment: false,
        environment: env,
      );

      bool dartToolConsentRecorded(String home) {
        final config = File(_configPath(home));
        return config.existsSync() &&
            RegExp(
              r'^dart-tool=\S+,1$',
              multiLine: true,
            ).hasMatch(config.readAsStringSync());
      }

      test('does not suppress sub-tools or record consent', () async {
        final p = project(mainSrc: _printAnalyticsEnvSrc);
        final (:env, :home) = _setUpIsolatedHome(p, consented: false);

        final result = await runWith(p, env);
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: false'));
        // The config file was created, but the Dart CLI did not record that
        // it showed the consent message.
        expect(File(_configPath(home)).existsSync(), isTrue);
        expect(dartToolConsentRecorded(home), isFalse);

        // A second run is still a first run as far as consent goes.
        final second = await runWith(p, env);
        expect(second.exitCode, 0);
        expect(second.stdout, contains('DASH__SUPPRESS_ANALYTICS: false'));
        expect(dartToolConsentRecorded(home), isFalse);
      });

      test('outdated consent version does not suppress sub-tools', () async {
        final p = project(mainSrc: _printAnalyticsEnvSrc);
        final (:env, :home) = _setUpIsolatedHome(p, consented: false);
        File(_configPath(home))
          ..createSync(recursive: true)
          ..writeAsStringSync('reporting=1\ndart-tool=2026-01-01,0\n');

        final result = await runWith(p, env);
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: false'));
        expect(dartToolConsentRecorded(home), isFalse);
      });

      test('with --suppress-analytics suppresses sub-tools', () async {
        final p = project(mainSrc: _printAnalyticsEnvSrc);
        final env = _setUpIsolatedHome(
          p,
          consented: false,
          extra: {'BOT': null},
        ).env;

        final result = await runWith(
          p,
          env,
          dartArgs: const ['--suppress-analytics'],
        );
        expect(result.exitCode, 0);
        expect(result.stdout, contains('DASH__SUPPRESS_ANALYTICS: true'));
      });
    },
    // Internal builds have no consent flow and never create the config file.
    //
    // `NoOpAnalytics().isExternal` reflects the package's build-time
    // `isExternal` constant (`Analytics.fake` would not: it defaults to
    // `true`). This assumes the test process and the SDK under test were built
    // with the same value, which holds when both come from the same checkout.
    skip: NoOpAnalytics().isExternal
        ? false
        : 'Consent only applies to external builds.',
  );
}
