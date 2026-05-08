// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pub_formats/pub_formats.dart';
import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

/// A package in the Dart SDK that we use for testing.
///
/// This package is on pub.dev, and on a Git repo, and on disk. So, this can be
/// used for testing hosted, git, and path installs.
///
/// Moreover it has an executables section in the pubspec.
const _packageForTest = 'vm_snapshot_analysis';

/// A valid version for [_packageForTest].
///
/// Not the newest version.
const _packageVersion = '0.7.5';

/// The name of an executable in [_packageForTest].
const _cliToolForTest = 'snapshot_analysis';

final _pathEnvVarSeparator = Platform.isWindows ? ';' : ':';

/// A package not in the Dart SDK repo. The Dart SDK repo takes too long to
/// clone.
const _gitPackageForTest = 'dart_app';

const String _dartDirectoryEnvKey = 'DART_DATA_HOME';

final _dartDevEntryScriptUri = resolveDartDevUri('bin/dartdev.dart');

final _sdkUri = resolveDartDevUri('.').resolve('../../');

final _packageRelativePath = Uri.directory('pkg/vm_snapshot_analysis/');

final _packageDir = Directory.fromUri(_sdkUri.resolveUri(_packageRelativePath));

/// Standalone, with its own pubspec.
final _package2RelativePath = Uri.directory('pkg/dartdev/test/data/dart_app/');

final _package2Dir = Directory.fromUri(
  _sdkUri.resolveUri(_package2RelativePath),
);

void main([List<String> args = const []]) async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    return;
  }

  final bool fromDartdevSource = args.contains('--source');
  final errorExitCode = fromDartdevSource
      ? /* Dartdev doesn't exit the process, it sends a message to the VM.*/ 0
      : 255;
  final argsFiltered = args.where((e) => e != '--source').toList();
  final testName = argsFiltered.isEmpty ? null : argsFiltered.join(' ');

  @isTest
  void skippableTest(
    String description,
    dynamic Function() body, {
    Timeout? timeout,
  }) {
    test(
      description,
      skip: !(testName == null || description.contains(testName)),
      timeout: timeout,
      body,
    );
  }

  final commandsHelpmessages = [
    (
      'install',
      '''
Install or upgrade a Dart CLI tool for global use.

Install all executables specified in a package's pubspec.yaml executables
section (https://dart.dev/tools/pub/pubspec#executables) on the PATH. If the
executables section doesn't exist, installs all `bin/*.dart` entry points as
executables.

If the same package has been previously installed, it will be overwritten.

You can specify a package to install from pub.dev, a git repository, or a
local path using the `<package>[@<descriptor>]` syntax.

The `@<descriptor>` can be a version constraint (for hosted packages) or a
pub descriptor (consistent with pubspec.yaml).

Examples:
  dart install <pkg>
  dart install <pkg>@^3.0.0
  dart install '<pkg>@{hosted: https://pub.dev, version: ^3.0.0}'
  dart install '<pkg>@{git: {url: https://github.com/<owner>/<repo>, path: <path>}}'
  dart install '<pkg>@{path: /path/to/<pkg>}'

See https://dart.dev/to/package-descriptors for more details.

Usage: dart install <package>[@<descriptor>]
-h, --help         Print this usage information.
    --overwrite    Overwrite executables from other packages with the same name.

Run "dart help" to see global options.''',
    ),
    (
      'installed',
      '''
List globally installed Dart CLI tools.

Usage: dart installed [arguments]
-h, --help        Print this usage information.
-a, --[no-]all    Also list packages which are currently not active.
                  Active package have executables on `PATH`.
                  App bundles of packages on disk which have no executables
                  on `PATH` are non-active.

Run "dart help" to see global options.
''',
    ),
    (
      'uninstall',
      '''
Remove a globally installed Dart CLI tool.

Completely deletes all installed versions of <package> and all executables from
<package> placed on PATH.

Usage: dart uninstall <package>
-h, --help    Print this usage information.

Run "dart help" to see global options.
''',
    ),
  ];
  for (final (command, helpMessage) in commandsHelpmessages) {
    skippableTest('dart $command --help', timeout: longTimeout, () async {
      final result = await _runDartdev(
        fromDartdevSource,
        command,
        ['--help'],
        null,
        {},
      );
      expect(result.stdout, contains(helpMessage));
    });
  }

  final argumentss = [
    (null, [_packageForTest]),
    (null, [_packageForTest, _packageVersion]),
    (null, ['$_packageForTest@$_packageVersion']),
    (null, ['$_packageForTest@{"version": "$_packageVersion"}']),
    (null, ['$_packageForTest@{version: $_packageVersion}']),
    (
      null,
      [_packageForTest, _packageVersion, '--hosted-url', 'https://pub.dev/'],
    ),
    (null, [_packageDir.path]),
    (_sdkUri, [_packageRelativePath.path]),
    (_packageDir.uri, ['.']),
  ];

  for (final (workingDirectory, arguments) in argumentss) {
    var testName = arguments.join(' ');
    if (workingDirectory != null) {
      testName += ' in ${workingDirectory.toFilePath()}';
    }

    skippableTest('dart install $testName', timeout: longTimeout, () async {
      await inTempDir((tempUri) async {
        final binDir = Directory.fromUri(tempUri.resolve('install/bin'));

        final environment = {
          _dartDirectoryEnvKey: tempUri.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        final installResult = await _runDartdev(
          fromDartdevSource,
          'install',
          arguments,
          workingDirectory,
          environment,
        );
        // No hooks.
        expect(installResult.stdout, isNot(contains('Running build hooks')));
        expect(installResult.stdout, isNot(contains('Running link hooks')));

        await _runToolForTest(environment);

        final installedResult = await _runDartdev(
          fromDartdevSource,
          'installed',
          [],
          null,
          environment,
        );
        final installedLines = installedResult.stdout.split('\n');
        expect(installedLines.where((e) => e.isNotEmpty).length, equals(1));
        final installedLine = installedLines.first;
        expect(installedLine, startsWith(_packageForTest));
        if (arguments.contains(_packageVersion)) {
          expect(installedLine, equals('$_packageForTest $_packageVersion'));
        }
        if (arguments.contains(_packageRelativePath.toString())) {
          expect(
            installedLine,
            stringContainsInOrder([_packageRelativePath.toString(), '" at 20']),
          );
        }

        await _runDartdev(
          fromDartdevSource,
          'uninstall',
          [_packageForTest],
          null,
          environment,
        );
      });
    });
  }

  final argumentssGit = [
    ['git'],
    ['git', '--git-path', '--git-ref'],
    ['git-descriptor'],
  ];

  for (final testArguments in argumentssGit) {
    var testName = testArguments.join(' ');

    skippableTest('dart install $testName', timeout: longTimeout, () async {
      await inTempDir((tempUri) async {
        final gitUri = tempUri.resolve('app.git/');
        await Directory.fromUri(gitUri.resolve('bin/')).create(recursive: true);
        for (final file in [
          'pubspec.yaml',
          'bin/dart_app.dart',
          'bin/other_app.dart',
        ]) {
          await File.fromUri(
            _package2Dir.uri.resolve(file),
          ).copy(gitUri.resolve(file).toFilePath());
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
        final gitPath = './';
        final List<String> arguments;
        if (testArguments.contains('git-descriptor')) {
          arguments = [
            'dart_app@{git: {url: ${gitUri.toFilePath()}, ref: $gitRef}}',
          ];
        } else {
          arguments = [
            gitUri.toFilePath(),
            if (testArguments.contains('--git-path')) ...[
              '--git-path',
              gitPath,
            ],
            if (testArguments.contains('--git-ref')) ...['--git-ref', gitRef],
          ];
        }

        final dartDataHome = tempUri.resolve('dart_home/');
        await Directory.fromUri(dartDataHome).create();
        final binDir = Directory.fromUri(dartDataHome.resolve('install/bin'));

        final environment = {
          _dartDirectoryEnvKey: dartDataHome.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        await _runDartdev(
          fromDartdevSource,
          'install',
          arguments,
          null,
          environment,
        );

        final installedResult = await _runDartdev(
          fromDartdevSource,
          'installed',
          [],
          null,
          environment,
        );
        final installedLines = installedResult.stdout.split('\n');
        expect(installedLines.where((e) => e.isNotEmpty).length, equals(1));
        final installedLine = installedLines.first;
        expect(installedLine, startsWith(_gitPackageForTest));
        expect(installedLine, contains(' at "${gitRef.substring(0, 8)}"'));

        await _runDartdev(
          fromDartdevSource,
          'uninstall',
          [_gitPackageForTest],
          null,
          environment,
        );
      });
    });
  }

  skippableTest('dart install ~/.dart/install/bin/ not on PATH', () async {
    await inTempDir((tempUri) async {
      final environment = {_dartDirectoryEnvKey: tempUri.toFilePath()};

      await inTempDir((tempUri) async {
        final installResult = await _runDartdev(
          fromDartdevSource,
          'install',
          [_packageForTest],
          null,
          environment,
        );
        if (Platform.isWindows) {
          expect(
            installResult.stdout,
            stringContainsInOrder([
              'Warning: Dart installs executables into ',
              'which is not on your path.',
              "You can fix that by adding that directory to your system's ",
              '"Path" environment variable.',
              'A web search for "configure windows path" will show you how.',
            ]),
          );
        } else {
          expect(
            installResult.stdout,
            stringContainsInOrder([
              'Warning: Dart installs executables into',
              'You can fix that by adding this to your shell\'s config file ',
              'export PATH="\$PATH":',
            ]),
          );
        }
      });
    });
  });

  skippableTest(
    'dart install dart_app (with build hooks and code assets)',
    timeout: longTimeout,
    () async {
      await inTempDir((tempUri) async {
        final binDir = Directory.fromUri(tempUri.resolve('install/bin'));

        final environment = {
          _dartDirectoryEnvKey: tempUri.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        await nativeAssetsTest('dart_app', (dartAppUri) async {
          // Add a second executable.
          final entryPoint1 = File.fromUri(
            dartAppUri.resolve('bin/dart_app.dart'),
          );
          final entryPoint2 = File.fromUri(
            dartAppUri.resolve('bin/dart_app_copy.dart'),
          );
          final entryPoint1Contents = await entryPoint1.readAsString();
          final entryPoint2Contents = entryPoint1Contents.replaceAll('5', '42');
          await entryPoint2.writeAsString(entryPoint2Contents);
          final pubspecFile = File.fromUri(dartAppUri.resolve('pubspec.yaml'));
          final pubspecOld = pubspecFile.readAsStringSync().replaceAll(
            '\r\n',
            '\n',
          );
          final pubspecNew = pubspecOld.replaceAll(
            '''executables:
  dart_app:'''
                .replaceAll('\r\n', '\n'),
            '''executables:
  dart_app:
  dart_app_copy:'''
                .replaceAll('\r\n', '\n'),
          );
          expect(pubspecNew, isNot(equals(pubspecOld)));
          pubspecFile.writeAsStringSync(pubspecNew);

          final installResult = await _runDartdev(
            fromDartdevSource,
            'install',
            [dartAppUri.toFilePath()],
            null,
            environment,
          );

          expect(installResult.stdout, contains('Running build hooks'));
          expect(installResult.stdout, contains('Running link hooks'));

          for (final (tool, someInt) in [
            ('dart_app', 5),
            ('dart_app_copy', 42),
          ]) {
            final toolResult = await runProcess(
              // Note this has `runInShell: true` under it to ensure PATHEXT is used on
              // Windows so that invoking an executable without extension works.
              executable: Uri.file(tool),
              // Run in some unrelated directory ensuring PATH is picked up.
              workingDirectory: Directory.systemTemp.uri,
              logger: logger,
              environment: environment,
            );
            expect(
              toolResult.stdout,
              stringContainsInOrder([
                'add($someInt, 6) = ${someInt + 6}',
                'subtract($someInt, 6) = ${someInt - 6}',
              ]),
            );
            expect(toolResult.exitCode, 0);
          }
        });
      });
    },
  );

  skippableTest('dart install --overwrite', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      final binDir = Directory.fromUri(tempUri.resolve('install/bin'));

      final environment = {
        _dartDirectoryEnvKey: tempUri.toFilePath(),
        'PATH':
            '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
      };

      await nativeAssetsTest('dart_app', (dartAppUri) async {
        await _runDartdev(
          fromDartdevSource,
          'install',
          [dartAppUri.toFilePath()],
          null,
          environment,
        );

        // Not overwriting, but the same package is fine.
        await _runDartdev(
          fromDartdevSource,
          'install',
          [dartAppUri.toFilePath()],
          null,
          environment,
        );

        final pubspecFile = File.fromUri(dartAppUri.resolve('pubspec.yaml'));
        final pubspecContents = await pubspecFile.readAsString();
        final pubspecContentsNew = pubspecContents.replaceFirst(
          'dart_app',
          'a_different_name',
        );
        await pubspecFile.writeAsString(pubspecContentsNew);

        // Trying to install an executable with the same name from a different
        // package should fail.
        await _runDartdev(
          fromDartdevSource,
          'install',
          [dartAppUri.toFilePath()],
          null,
          environment,
          expectedExitCode: errorExitCode,
        );

        // Overwriting is fine.
        await _runDartdev(
          fromDartdevSource,
          'install',
          [dartAppUri.toFilePath(), '--overwrite'],
          null,
          environment,
        );

        // Using --overwrite leads to inactive versions.
        // `dart installed --all` should also report the non-active versions.
        for (final all in [true, false]) {
          final installedResult = await _runDartdev(
            fromDartdevSource,
            'installed',
            [if (all) '--all'],
            null,
            environment,
          );
          final installedLines = installedResult.stdout
              .split('\n')
              .where((e) => e.isNotEmpty)
              .toList();
          if (all) {
            expect(installedLines, hasLength(2));
            expect(installedLines, contains(startsWith('dart_app')));
          } else {
            expect(installedLines, hasLength(1));
            expect(installedLines, isNot(contains(startsWith('dart_app'))));
          }
        }
      });
    });
  });

  skippableTest('dart install check exit codes', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      final binDir = Directory.fromUri(tempUri.resolve('install/bin'));

      final environment = {
        _dartDirectoryEnvKey: tempUri.toFilePath(),
        'PATH':
            '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
      };

      const appName = 'test_app';
      final dartAppUri = tempUri.resolve('$appName/');
      final pubspec = File.fromUri(dartAppUri.resolve('pubspec.yaml'));
      await pubspec.create(recursive: true);
      await pubspec.writeAsString(
        jsonEncode(
          PubspecYamlFileSyntax(
            name: appName,
            environment: EnvironmentSyntax(
              sdk: '^${Platform.version.split(' ').first}',
            ),
            executables: {appName: appName},
          ).json,
        ),
      );
      final mainFile = File.fromUri(dartAppUri.resolve('bin/$appName.dart'));
      await mainFile.create(recursive: true);
      mainFile.writeAsString('''
import 'dart:io';

void main(List<String> args) {
  exit(int.parse(args.first));
}
''');
      await _runDartdev(
        fromDartdevSource,
        'install',
        [dartAppUri.toFilePath()],
        null,
        environment,
      );

      const testExitCode = 55;
      final toolResult = await runProcess(
        // Note this has `runInShell: true` under it to ensure PATHEXT is used on
        // Windows so that invoking an executable without extension works.
        executable: Uri.file(appName),
        // Run in some unrelated directory ensuring PATH is picked up.
        workingDirectory: Directory.systemTemp.uri,
        arguments: ['$testExitCode'],
        logger: logger,
        environment: environment,
        expectedExitCode: testExitCode,
      );
      expect(toolResult.exitCode, testExitCode);
    });
  });

  skippableTest(
    'dart install hooks user-defines and failures',
    timeout: longTimeout,
    () async {
      await inTempDir((tempUri) async {
        final binDir = Directory.fromUri(tempUri.resolve('install/bin'));

        final environment = {
          _dartDirectoryEnvKey: tempUri.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        const packageName = 'test_app';
        final dartAppUri = tempUri.resolve('$packageName/');
        final pubspec = File.fromUri(dartAppUri.resolve('pubspec.yaml'));
        await pubspec.create(recursive: true);
        final mainFile = File.fromUri(
          dartAppUri.resolve('bin/$packageName.dart'),
        );
        await mainFile.create(recursive: true);
        mainFile.writeAsString('''
void main(List<String> args) { }
''');
        final buildHookFile = File.fromUri(
          dartAppUri.resolve('hook/build.dart'),
        );
        await buildHookFile.create(recursive: true);
        buildHookFile.writeAsString('''
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final myUserDefine = input.userDefines['my_user_define'];
    if (myUserDefine == null) {
      throw Exception('Expected a user define');
    }
  });
}
''');
        for (final addUserDefine in [true, false]) {
          await pubspec.writeAsString(
            jsonEncode(
              PubspecYamlFileSyntax(
                name: packageName,
                environment: EnvironmentSyntax(
                  sdk: '^${Platform.version.split(' ').first}',
                ),
                executables: {packageName: packageName},
                dependencies: {
                  'hooks': PathDependencySourceSyntax(
                    path$: sdkRootUri
                        .resolve('third_party/pkg/native/pkgs/hooks/')
                        .toFilePath(),
                  ),
                },
                hooks: HooksSyntax(
                  userDefines: {
                    packageName: {
                      if (addUserDefine) 'my_user_define': 'a_value,',
                    },
                  },
                ),
              ).json,
            ),
          );
          final installResult = await _runDartdev(
            fromDartdevSource,
            'install',
            [dartAppUri.toFilePath()],
            null,
            environment,
            expectedExitCode: addUserDefine ? 0 : errorExitCode,
          );
          if (addUserDefine) {
            expect(installResult.exitCode, equals(0));
            expect(installResult.stderr, isEmpty);
          } else {
            // Check that build hook failures are surfaced and that error messages
            // are visible.
            expect(installResult.exitCode, equals(errorExitCode));
            expect(installResult.stderr, contains('Expected a user define'));
          }
        }
      });
    },
  );

  skippableTest(
    'dart install uninstalls old versions',
    timeout: longTimeout,
    () async {
      await inTempDir((tempUri) async {
        final binDir = Directory.fromUri(tempUri.resolve('install/bin'));

        final environment = {
          _dartDirectoryEnvKey: tempUri.toFilePath(),
          'PATH':
              '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
        };

        // Install two versions.
        await _runDartdev(
          fromDartdevSource,
          'install',
          ['.'],
          _packageDir.uri,
          environment,
        );
        final installResult = await _runDartdev(
          fromDartdevSource,
          'install',
          [_packageForTest, _packageVersion],
          null,
          environment,
        );
        expect(
          installResult.stdout,
          stringContainsInOrder(['Uninstalling ', _packageForTest]),
        );

        // `--all` should also report the non-active versions.
        Future<List<String>> runInstalled() async {
          final installedResult = await _runDartdev(
            fromDartdevSource,
            'installed',
            ['--all'],
            null,
            environment,
          );
          final installedLines = installedResult.stdout
              .split('\n')
              .where((e) => e.isNotEmpty)
              .toList();
          return installedLines;
        }

        expect(await runInstalled(), hasLength(1));

        // `uninstall` uninstalls all versions.
        await _runDartdev(
          fromDartdevSource,
          'uninstall',
          [_packageForTest],
          null,
          environment,
        );
        expect(await runInstalled(), hasLength(0));
      });
    },
  );

  skippableTest('dart uninstall', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      final environment = {_dartDirectoryEnvKey: tempUri.toFilePath()};

      // `uninstall` should have a non-zero exit if nothing was uninstalled.
      await _runDartdev(
        fromDartdevSource,
        'uninstall',
        [_packageForTest],
        null,
        environment,
        expectedExitCode: errorExitCode,
      );
    });
  });

  skippableTest('dart uninstall while running', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      final binDir = Directory.fromUri(tempUri.resolve('install/bin'));

      final environment = {
        _dartDirectoryEnvKey: tempUri.toFilePath(),
        'PATH':
            '${binDir.path}$_pathEnvVarSeparator${Platform.environment['PATH']!}',
      };

      const packageName = 'test_app';
      final dartAppUri = tempUri.resolve('$packageName/');
      final pubspec = File.fromUri(dartAppUri.resolve('pubspec.yaml'));
      await pubspec.create(recursive: true);
      await pubspec.writeAsString(
        jsonEncode(
          PubspecYamlFileSyntax(
            name: packageName,
            environment: EnvironmentSyntax(
              sdk: '^${Platform.version.split(' ').first}',
            ),
            executables: {packageName: packageName},
          ).json,
        ),
      );
      final mainFile = File.fromUri(
        dartAppUri.resolve('bin/$packageName.dart'),
      );
      await mainFile.create(recursive: true);
      mainFile.writeAsString('''
void main(List<String> args) async {
  await Future.delayed(Duration(days: 1000000));
}
''');
      Future<RunProcessResult> doInstall(int expectedExitCode) async {
        return await _runDartdev(
          fromDartdevSource,
          'install',
          [dartAppUri.toFilePath()],
          null,
          environment,
          expectedExitCode: expectedExitCode,
        );
      }

      await doInstall(0);

      final runningProcess = await Process.start(
        packageName,
        [],
        environment: environment,
        runInShell: true,
      );

      final installWhileRunningResult = await doInstall(
        Platform.isWindows ? errorExitCode : 0,
      );
      if (Platform.isWindows) {
        expect(
          installWhileRunningResult.stderr,
          contains('The application might be in use.'),
        );
      } else {
        expect(installWhileRunningResult.stderr, isEmpty);
      }

      final uninstallWhileRunningResult = await _runDartdev(
        fromDartdevSource,
        'uninstall',
        [packageName],
        null,
        environment,
        expectedExitCode: Platform.isWindows ? errorExitCode : 0,
      );
      if (Platform.isWindows) {
        expect(
          uninstallWhileRunningResult.stderr,
          contains('The application might be in use.'),
        );
      } else {
        expect(uninstallWhileRunningResult.stderr, isEmpty);
      }

      runningProcess.kill();
    });
  });
}

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

/// Runs [_cliToolForTest] and expects the help message.
Future<RunProcessResult> _runToolForTest(
  Map<String, String> environment,
) async {
  final toolResult = await runProcess(
    // Note this has `runInShell: true` under it to ensure PATHEXT is used on
    // Windows so that invoking an executable without extension works.
    executable: Uri.file(_cliToolForTest),
    arguments: ['--help'],
    // Run in some unrelated directory ensuring PATH is picked up.
    workingDirectory: Directory.systemTemp.uri,
    logger: logger,
    environment: environment,
  );
  expect(
    toolResult.stdout,
    stringContainsInOrder([
      'Tools for binary size analysis of Dart VM AOT snapshots.',
    ]),
  );
  expect(toolResult.exitCode, 0);
  return toolResult;
}
