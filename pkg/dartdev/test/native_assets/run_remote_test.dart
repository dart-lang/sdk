// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:pub_formats/pub_formats.dart';
import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

final _sdkUri = resolveDartDevUri('.').resolve('../../');

final _package2RelativePath = Uri.directory('pkg/dartdev/test/data/dart_app/');

final _package2Dir = Directory.fromUri(
  _sdkUri.resolveUri(_package2RelativePath),
);

final _pathEnvVarSeparator = Platform.isWindows ? ';' : ':';

const String _dartDirectoryEnvKey = 'DART_DATA_HOME';

// Set to true for debugging dartdev from the test.
const fromDartdevSource = false;

void main() async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    return;
  }

  final errorExitCode = fromDartdevSource
      ? /* Dartdev doesn't exit the process, it sends a message to the VM.*/ 0
      : 255;
  final usageExitCode = fromDartdevSource
      ? /* Dartdev doesn't exit the process, it sends a message to the VM.*/ 0
      : 64;

  test('dart run --help', timeout: longTimeout, () async {
    final result = await _runDartdev(
      fromDartdevSource,
      'run',
      ['--help'],
      null,
      {},
    );
    printOnFailure('stdout:\n${result.stdout}');
    expect(
      result.stdout,
      contains('''
Run a Dart program from a file or a local or remote package.

Usage:

Running a local script or package executable:
  dart run [vm-options] <dart-file>|<local-package>[:<executable>] args
Running a remote package executable:
  dart run <remote-package>[:<executable?]@[<descriptor>]> [args]

<dart-file>
  A path to a Dart script (e.g., `bin/main.dart`).

<local-package>
  The name of a package in the local package resolution.

<executable>
  The name of an executable in the package to execute.

  For example, `dart run test:test` runs the `test` executable from the `test` package.
  If the executable is not specified, the package name is used.

<descriptor>
  A YAML formatted string that describes how to locate the
  remote package, the same you could use in a pubspec.

  For example, to run the latest stable `pubviz` package from pub.dev:
    dart run pubviz@
  To specify a version constraint:
    dart run pubviz@^4.0.0
  To specify a custom package host:
    dart run 'pubviz@{hosted: https://my_repository.com, version: ^1.0.0}'
  To run from a git package:
    dart run 'pubviz@{git: https://github.com/kevmoo/pubviz}'

See https://dart.dev/to/package-descriptors for more details.'''),
    );
  });

  for (final argument in [
    'vm_snapshot_analysis:snapshot_analysis@0.7.5',
    'vm_snapshot_analysis:snapshot_analysis@^0.7.5',
    'vm_snapshot_analysis:snapshot_analysis@', // Resolves to latest stable version.
    'vm_snapshot_analysis:snapshot_analysis@{hosted: https://pub.dev}',
  ]) {
    test('dart run  $argument', timeout: longTimeout, () async {
      await inTempDir((tempUri) async {
        final dartDataHome = tempUri.resolve('dart_home/');
        await Directory.fromUri(dartDataHome).create();
        final binDir = Directory.fromUri(dartDataHome.resolve('install/bin'));

        final environment = <String, String>{
          _dartDirectoryEnvKey: dartDataHome.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        final runResult = await _runDartdev(
          fromDartdevSource,
          'run',
          [
            argument,
            // Make sure to pass arguments that influence stdout.
            'compare',
            '--help',
          ],
          null,
          environment,
        );
        expect(
          runResult.stdout,
          stringContainsInOrder([
            'Usage: snapshot_analysis compare <old.json> <new.json>',
          ]),
        );
        expect(runResult.exitCode, 0);
      });
    });
  }

  test('dart run remote from git', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      final (gitUri, gitRef) = await _setupSimpleGitRepo(tempUri);
      for (final (argument, expectedResult) in [
        ('dart_app@{git: ${gitUri.toString()}}', 'Hello Alice and Bob'),
        (
          'dart_app:other_app@{git: ${gitUri.toString()}}',
          'Hello from other app Alice and Bob',
        ),
      ]) {
        final arguments = [
          argument,
          // Make sure to pass arguments that influence stdout.
          'Alice',
          'and',
          'Bob',
        ];

        final dartDataHome = tempUri.resolve('dart_home/');
        await Directory.fromUri(dartDataHome).create();
        final binDir = Directory.fromUri(dartDataHome.resolve('install/bin'));

        final environment = {
          _dartDirectoryEnvKey: dartDataHome.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        final runResult = await _runDartdev(
          fromDartdevSource,
          'run',
          arguments,
          null,
          environment,
        );

        expect(runResult.stdout, contains(expectedResult));
        expect(runResult.exitCode, 0);
      }
    });
  });

  final errorArgumentss = [
    (
      ['this_package_does_not_exist_12345@'],
      'could not find package this_package_does_not_exist_12345 at',
      errorExitCode,
    ),
    (
      ['--enable-asserts', 'vm_snapshot_analysis@'],
      '--enable-asserts cannot be used in remote runs',
      usageExitCode,
    ),
    (['my_package@{,bad,descriptor,}'], '{,bad,descriptor,}', usageExitCode),
  ];
  for (final (errorArguments, error, exitCode) in errorArgumentss) {
    test('dart run ${errorArguments.join(' ')}', timeout: longTimeout, () async {
      await inTempDir((tempUri) async {
        final dartDataHome = tempUri.resolve('dart_home/');
        await Directory.fromUri(dartDataHome).create();
        final binDir = Directory.fromUri(dartDataHome.resolve('install/bin'));

        final environment = <String, String>{
          _dartDirectoryEnvKey: dartDataHome.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        final runResult = await _runDartdev(
          fromDartdevSource,
          'run',
          errorArguments,
          null,
          environment,
          expectedExitCode: exitCode,
        );
        expect(runResult.stderr, contains(error));
      });
    });
  }

  test(
    'dart run error from git with build hook failure',
    timeout: longTimeout,
    () async {
      await inTempDir((tempUri) async {
        final dartDataHome = tempUri.resolve('dart_home/');
        await Directory.fromUri(dartDataHome).create();
        final binDir = Directory.fromUri(dartDataHome.resolve('install/bin'));

        final environment = {
          _dartDirectoryEnvKey: dartDataHome.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        const packageName = 'test_app_with_failing_hook';
        final (gitUri, _) = await _setupGitRepo(
          tempUri,
          repoName: '$packageName.git',
          files: {
            'pubspec.yaml': jsonEncode(
              PubspecYamlFileSyntax(
                name: packageName,
                environment: EnvironmentSyntax(
                  sdk: '^${Platform.version.split(' ').first}',
                ),
                executables: {packageName: packageName},
              ).json,
            ),
            'bin/$packageName.dart': '''
void main(List<String> args) {
  print('This should not be printed.');
}
''',
            'hook/build.dart': '''
void main(List<String> args) async {
  throw Exception('This build hook is designed to fail.');
}
''',
          },
        );

        final runResult = await _runDartdev(
          fromDartdevSource,
          'run',
          ['test_app_with_failing_hook@{git: ${gitUri.toFilePath()}}'],
          null,
          environment,
          expectedExitCode: errorExitCode,
        );

        expect(
          runResult.stderr,
          contains('This build hook is designed to fail.'),
        );
        expect(
          runResult.stdout,
          isNot(contains('This should not be printed.')),
        );
      });
    },
  );

  test('dart run caches git package', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      final (gitUri, gitRef) = await _setupSimpleGitRepo(tempUri);

      final arguments = ['dart_app@{git: ${gitUri.toFilePath()}}', 'World'];

      // 2. Setup environment
      final dartDataHome = tempUri.resolve('dart_home/');
      await Directory.fromUri(dartDataHome).create();
      final binDir = Directory.fromUri(dartDataHome.resolve('install/bin'));
      final environment = {
        _dartDirectoryEnvKey: dartDataHome.toFilePath(),
        'PATH':
            '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
      };

      // 3. First run - should build
      final firstRunResult = await _runDartdev(
        fromDartdevSource,
        'run',
        arguments,
        null,
        environment,
      );

      expect(firstRunResult.stdout, contains('Hello World'));
      expect(firstRunResult.exitCode, 0);
      expect(firstRunResult.stdout, contains('Generated: '));
      // No hooks.
      expect(firstRunResult.stdout, isNot(contains('Running build hooks')));
      expect(firstRunResult.stdout, isNot(contains('Running link hooks')));

      // 4. Second run - should be cached
      final secondRunResult = await _runDartdev(
        fromDartdevSource,
        'run',
        arguments,
        null,
        environment,
      );

      expect(secondRunResult.stdout, contains('Hello World'));
      expect(secondRunResult.exitCode, 0);
      expect(secondRunResult.stdout, isNot(contains('Generated: ')));
    });
  });

  for (final verbosityError in [true, false]) {
    final testName = verbosityError ? ' --verbosity=error' : '';
    test(
      'dart run from git with build hook$testName',
      timeout: longTimeout,
      () async {
        await inTempDir((tempUri) async {
          const packageName = 'test_app_with_hook';
          final (gitUri, gitRef) = await _setupGitRepoWithHook(
            tempUri,
            packageName: packageName,
          );

          final arguments = [
            if (verbosityError) '--verbosity=error',
            'test_app_with_hook@{git: {url: ${gitUri.toFilePath()}, ref: $gitRef}}',
            'ignored',
            'arguments',
          ];

          final dartDataHome = tempUri.resolve('dart_home/');
          await Directory.fromUri(dartDataHome).create();
          final binDir = Directory.fromUri(dartDataHome.resolve('install/bin'));

          final environment = {
            _dartDirectoryEnvKey: dartDataHome.toFilePath(),
            'PATH':
                '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
          };

          final runResult = await _runDartdev(
            fromDartdevSource,
            'run',
            arguments,
            null,
            environment,
          );

          expect(runResult.stdout, contains('Hello World'));
          expect(runResult.exitCode, 0);
          if (verbosityError) {
            expect(runResult.stdout, isNot(contains('Running build hooks')));
            expect(runResult.stdout, isNot(contains('Running link hooks')));
            expect(runResult.stdout, isNot(contains('Generated: ')));
            // Should have no other output than the program.
            expect(runResult.stdout.trim(), equals('Hello World'));
          } else {
            expect(runResult.stdout, contains('Running build hooks'));
            expect(runResult.stdout, contains('Running link hooks'));
            expect(runResult.stdout, contains('Generated: '));
          }
        });
      },
    );
  }
}

Future<(Uri gitUri, String gitRef)> _setupGitRepo(
  Uri tempUri, {
  String repoName = 'app.git',
  required Map<String, String> files,
}) async {
  final gitUri = tempUri.resolve('$repoName/');
  for (final entry in files.entries) {
    final file = File.fromUri(gitUri.resolve(entry.key));
    await file.create(recursive: true);
    await file.writeAsString(entry.value);
  }

  for (final commands in [
    ['init'],
    ['add', '.'],
    ['commit', '-m', '"Initial commit"'],
  ]) {
    final gitResult = await Process.run(
      'git',
      commands,
      workingDirectory: gitUri.toFilePath(),
    );
    if (gitResult.exitCode != 0) {
      throw ProcessException('git', commands, gitResult.stderr);
    }
  }
  final gitRef =
      ((await Process.run('git', [
                'rev-parse',
                'HEAD',
              ], workingDirectory: gitUri.toFilePath())).stdout
              as String)
          .trim();
  return (gitUri, gitRef);
}

Future<(Uri gitUri, String gitRef)> _setupGitRepoWithHook(
  Uri tempUri, {
  String packageName = 'test_app_with_hook',
}) async {
  return await _setupGitRepo(
    tempUri,
    repoName: '$packageName.git',
    files: {
      'pubspec.yaml': jsonEncode(
        PubspecYamlFileSyntax(
          name: packageName,
          environment: EnvironmentSyntax(sdk: '^3.8.0'),
          executables: {packageName: null},
          dependencies: {
            // Git dependencies can't have path dependencies outside the git repo
            // so use a published dependency.
            'hooks': HostedDependencySourceSyntax(version: '^1.0.0'),
          },
        ).json,
      ),
      'bin/$packageName.dart': '''
void main(List<String> args) {
  print('Hello World');
}
''',
      'hook/build.dart': '''
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // Succeeds.
  });
}
''',
      'hook/link.dart': '''
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await link(args, (input, output) async {
    // Succeeds.
  });
}
''',
    },
  );
}

Future<(Uri gitUri, String gitRef)> _setupSimpleGitRepo(Uri tempUri) async {
  return await _setupGitRepo(
    tempUri,
    files: {
      'pubspec.yaml': await File.fromUri(
        _package2Dir.uri.resolve('pubspec.yaml'),
      ).readAsString(),
      'bin/dart_app.dart': await File.fromUri(
        _package2Dir.uri.resolve('bin/dart_app.dart'),
      ).readAsString(),
      'bin/other_app.dart': await File.fromUri(
        _package2Dir.uri.resolve('bin/other_app.dart'),
      ).readAsString(),
    },
  );
}

final _dartDevEntryScriptUri = resolveDartDevUri('bin/dartdev.dart');

Future<RunProcessResult> _runDartdev(
  bool fromDartdevSource,
  String command,
  List<String> arguments,
  Uri? workingDirectory,
  Map<String, String> environment, {
  int expectedExitCode = 0,
}) async {
  final installResult = await runDart(
    arguments: [
      if (fromDartdevSource) _dartDevEntryScriptUri.toFilePath(),
      command,
      ...arguments,
    ],
    workingDirectory: workingDirectory,
    logger: logger,
    environment: environment,
    expectExitCodeZero: false,
  );
  expect(installResult.exitCode, equals(expectedExitCode));
  return installResult;
}
