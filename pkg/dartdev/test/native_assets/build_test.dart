// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:test/test.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../utils.dart';
import 'helpers.dart';

String usingTargetOSMessageForPlatform(String targetOS) =>
    'Specializing Platform getters for target OS $targetOS.';
final String usingTargetOSMessage =
    usingTargetOSMessageForPlatform(Platform.operatingSystem);

void main([List<String> args = const []]) async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    return;
  }

  final dartDevEntryScriptUri = resolveDartDevUri('bin/dartdev.dart');

  final bool fromDartdevSource = args.contains('--source');

  /// The relative uri from the package root to the app bundle.
  final relativeBundleUri = Uri.directory(
      './build/cli/${OS.current}_${Architecture.current}/bundle/');

  for (final verbose in [true, false]) {
    final testModifier = verbose ? ' verbose' : '';
    test('dart build$testModifier', timeout: longTimeout, () async {
      await nativeAssetsTest('dart_app', (dartAppUri) async {
        final depFileUri = dartAppUri.resolve('my.d');
        final result = await runDart(
          arguments: [
            if (fromDartdevSource) dartDevEntryScriptUri.toFilePath(),
            'build',
            'cli',
            '--depfile=${depFileUri.toFilePath()}',
            if (verbose) '-v',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
        );
        expect(result.stdout, contains('Running build hooks'));
        expect(result.stdout, contains('Running link hooks'));
        expect(File.fromUri(depFileUri).existsSync(), true);
        if (verbose) {
          expect(result.stdout, contains(usingTargetOSMessage));
          expect(result.stdout, contains('build.dart'));
        } else {
          expect(result.stdout, isNot(contains('build.dart')));
        }

        final relativeExeUri = relativeBundleUri
            .resolve('bin/')
            .resolve(OS.current.executableFileName('dart_app'));
        final absoluteExeUri = dartAppUri.resolveUri(relativeExeUri);
        expect(await File.fromUri(absoluteExeUri).exists(), true);
        if (Platform.isLinux) {
          final relativeSnapshotUri = relativeBundleUri
              .resolve('lib/')
              .resolve(_linuxAotSnapshotFileName('dart_app'));
          expect(
            await File.fromUri(
              dartAppUri.resolveUri(relativeSnapshotUri),
            ).exists(),
            true,
          );
        }
        await _withTempDir((tempUri) async {
          // The link needs to have the same extension as the executable on
          // Windows to be able to be executable.
          final link = Link.fromUri(
              tempUri.resolve(OS.current.executableFileName('my_link')));
          await link.create(absoluteExeUri.toFilePath());
          for (final exeUri in [
            absoluteExeUri,
            relativeExeUri,
            link.uri,
            if (OS.current == OS.windows) ...[
              removeDotExe(absoluteExeUri),
              removeDotExe(relativeExeUri),
              removeDotExe(link.uri),
            ]
          ]) {
            final result = await runProcess(
              executable: exeUri,
              arguments: [],
              workingDirectory: dartAppUri,
              logger: logger,
            );
            expectDartAppStdout(result.stdout);
          }
        });
      });
    });
  }

  test('dart build native assets build failure', timeout: longTimeout,
      () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final buildDotDart = dartAppUri.resolve('../native_add/hook/build.dart');
      await File.fromUri(buildDotDart).writeAsString('''
void main(List<String> args) {
  throw UnimplementedError();
}
''');
      final result = await runDart(
        arguments: [
          'build',
          'cli',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.stderr,
        contains(
          'Running build hooks failed.',
        ),
      );
      expect(result.exitCode, 255);
    });
  });

  test('dart build and link dylib conflict', timeout: longTimeout, () async {
    await nativeAssetsTest('native_add_duplicate', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'build',
          'cli',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.stderr,
        contains(
          'Duplicate dynamic library file name',
        ),
      );
      expect(result.exitCode, 255);
    });
  });

  test('dart link assets', timeout: longTimeout, () async {
    await nativeAssetsTest('drop_dylib_link', (dartAppUri) async {
      await runDart(
        arguments: [
          'build',
          'cli',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );

      // Check that the build directory exists
      final libDirectory = Directory.fromUri(
          dartAppUri.resolveUri(relativeBundleUri).resolve('lib/'));
      expect(libDirectory.existsSync(), true);

      // Check that only one dylib is in the final application package
      final buildFiles = libDirectory.listSync(recursive: true);
      expect(
        buildFiles.where((file) => file.path.contains('add')),
        isNotEmpty,
      );
      expect(
        buildFiles.where((file) => file.path.contains('multiply')),
        isEmpty,
      );
    });
  });

  test('dart link assets', timeout: longTimeout, () async {
    await nativeAssetsTest('add_asset_link', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'build',
          'cli',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.exitCode,
        0, // linking is enabled so the build hook and link hook succeed.
      );

      // Check that the build directory exists
      final directory =
          Directory.fromUri(dartAppUri.resolveUri(relativeBundleUri));
      expect(directory.existsSync(), true);
      final dylib = OS.current.libraryFileName('add', DynamicLoadingBundled());
      expect(
        File.fromUri(directory.uri.resolve('lib/$dylib')).existsSync(),
        true,
      );
    });
  });

  test('do not delete project', () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          if (fromDartdevSource) dartDevEntryScriptUri.toFilePath(),
          'build',
          'cli',
          '--output=.'
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.exitCode,
        isNot(0), // The dartdev error code.
      );
    });
  });

  for (var filename in [
    'drop_dylib_recording_calls',
    'drop_dylib_recording_instances',
  ]) {
    test('Tree-shaking in $filename: An asset is dropped', timeout: longTimeout,
        () async {
      await recordUseTest('drop_dylib_recording', (dartAppUri) async {
        final addLib =
            OS.current.libraryFileName('add', DynamicLoadingBundled());
        final mulitplyLib =
            OS.current.libraryFileName('multiply', DynamicLoadingBundled());
        // Now try using the add symbol only, so the multiply library is
        // tree-shaken.

        await runDart(
          arguments: [
            '--enable-experiment=record-use',
            'build',
            'cli',
            '--target',
            'bin/$filename.dart',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
          expectExitCodeZero: true,
        );

        final bundleDirectory =
            Directory.fromUri(dartAppUri.resolveUri(relativeBundleUri));
        await runProcess(
          executable: bundleDirectory.uri
              .resolve('bin/')
              .resolve(OS.current.executableFileName(filename)),
          logger: logger,
          expectedExitCode: 0,
          throwOnUnexpectedExitCode: true,
          workingDirectory: dartAppUri,
        );

        // The build directory exists.
        expect(bundleDirectory.existsSync(), true);

        // The multiply asset has been treeshaken.
        expect(
          File.fromUri(bundleDirectory.uri.resolve('lib/$addLib')).existsSync(),
          true,
        );
        expect(
          File.fromUri(bundleDirectory.uri.resolve('lib/$mulitplyLib'))
              .existsSync(),
          false,
        );
      });
    });
  }

  test('dart build link hook cache isolation', timeout: longTimeout, () async {
    await recordUseTest('drop_dylib_recording', (dartAppUri) async {
      // First run: compile with target drop_dylib_recording_calls.dart.
      // This is the first compile, so it should run both build and link hooks.
      final run1 = await runDart(
        arguments: [
          '--enable-experiment=record-use',
          'build',
          'cli',
          '--target',
          'bin/drop_dylib_recording_calls.dart',
          '-v',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );
      expect(run1.stdout, contains('Running build hooks'));
      expect(run1.stdout, contains('Running link hooks'));
      expect(run1.stdout, isNot(contains('Skipping build for')));
      expect(run1.stdout, isNot(contains('Skipping link for')));

      // Second run: compile with target drop_dylib_recording_calls.dart again.
      // Since no inputs changed, it should skip both build and link hooks (cache hit).
      final run2 = await runDart(
        arguments: [
          '--enable-experiment=record-use',
          'build',
          'cli',
          '--target',
          'bin/drop_dylib_recording_calls.dart',
          '-v',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );
      expect(run2.stdout, contains('Skipping build for drop_dylib_recording'));
      expect(run2.stdout, contains('Skipping link for drop_dylib_recording'));
      expect(run2.stdout, isNot(contains('hook.dill')));

      // Third run: compile with target drop_dylib_recording_instances.dart.
      // The entrypoint target changed.
      // The build hook is NOT dependent on entrypoints, so build should remain a cache hit.
      // The link hook is dependent on entrypoints, so link must cache miss and run again.
      final run3 = await runDart(
        arguments: [
          '--enable-experiment=record-use',
          'build',
          'cli',
          '--target',
          'bin/drop_dylib_recording_instances.dart',
          '-v',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );
      expect(run3.stdout, contains('Skipping build for drop_dylib_recording'));
      expect(run3.stdout,
          isNot(contains('Skipping link for drop_dylib_recording')));
      expect(run3.stdout, contains('hook.dill'));
    });
  });

  test(
    'dart build with native dynamic linking',
    timeout: longTimeout,
    () async {
      await nativeAssetsTest('native_dynamic_linking', (packageUri) async {
        await runDart(
          arguments: [
            'build',
            'cli',
          ],
          workingDirectory: packageUri,
          logger: logger,
        );

        final bundleDirectory =
            Directory.fromUri(packageUri.resolveUri(relativeBundleUri));
        expect(bundleDirectory.existsSync(), true);

        File dylibFile(String name) {
          final libDirectoryUri = (bundleDirectory.uri.resolve('lib/'));
          final dylibBasename =
              OS.current.libraryFileName(name, DynamicLoadingBundled());
          return File.fromUri(libDirectoryUri.resolve(dylibBasename));
        }

        expect(dylibFile('add').existsSync(), true);
        expect(dylibFile('math').existsSync(), true);
        expect(dylibFile('debug').existsSync(), true);

        final proccessResult = await runProcess(
          executable: bundleDirectory.uri
              .resolve('bin/')
              .resolve(OS.current.executableFileName('native_dynamic_linking')),
          logger: logger,
          throwOnUnexpectedExitCode: true,
        );
        expect(proccessResult.stdout, contains('42'));
      });
    },
  );

  for (final usePubWorkspace in [true, false]) {
    test(
      'dart build with user defines',
      timeout: longTimeout,
      () async {
        await nativeAssetsTest('user_defines', usePubWorkspace: usePubWorkspace,
            (packageUri) async {
          await runDart(
            arguments: [
              'build',
              'cli',
            ],
            workingDirectory: packageUri,
            logger: logger,
          );

          final bundleDirectory =
              Directory.fromUri(packageUri.resolveUri(relativeBundleUri));
          expect(bundleDirectory.existsSync(), true);

          final proccessResult = await runProcess(
            executable: bundleDirectory.uri
                .resolve('bin/')
                .resolve(OS.current.executableFileName('user_defines')),
            logger: logger,
            throwOnUnexpectedExitCode: true,
          );
          expect(proccessResult.stdout, contains('Hello world!'));
        });
      },
    );
  }

  for (var sanitizer in ['asan', 'msan', 'tsan']) {
    test('dart build cli --target-sanitizer $sanitizer', timeout: longTimeout,
        () async {
      await nativeAssetsTest('dart_app', (dartAppUri) async {
        final result = await runDart(
          arguments: [
            'build',
            'cli',
            '--target-sanitizer',
            sanitizer,
          ],
          workingDirectory: dartAppUri,
          logger: logger,
          expectExitCodeZero: false,
        );
        final Directory binDir = File(Platform.resolvedExecutable).parent;
        final sanitizedRuntime =
            File.fromUri(binDir.uri.resolve('dartcliruntime_$sanitizer'));
        if (sanitizedRuntime.existsSync()) {
          expect(result.exitCode, 0);
          final relativeExeUri = relativeBundleUri
              .resolve('bin/')
              .resolve(OS.current.executableFileName('dart_app'));
          final absoluteExeUri = dartAppUri.resolveUri(relativeExeUri);
          expect(await File.fromUri(absoluteExeUri).exists(), true);
          final relativeSnapshotUri = relativeBundleUri
              .resolve('lib/')
              .resolve(_linuxAotSnapshotFileName('dart_app'));
          expect(
            await File.fromUri(
              dartAppUri.resolveUri(relativeSnapshotUri),
            ).exists(),
            true,
          );
        } else {
          expect(result.stderr, contains('dartcliruntime_$sanitizer'));
          expect(result.exitCode, 255);
        }
      });
    }, skip: !Platform.isLinux);
  }

  test('dart build cli with positional target is rejected',
      timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'build',
          'cli',
          'bin/dart_app.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(result.stderr, contains('Unexpected arguments'));
      expect(result.exitCode, isNot(0));
    });
  });

  test('dart build cli with custom entrypoint and custom package config',
      timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      await runPubGet(workingDirectory: dartAppUri, logger: logger);

      // 1. Create a custom entry point outside bin/
      final customDir = Directory.fromUri(dartAppUri.resolve('custom_dir/'));
      await customDir.create();
      final customEntryPoint = customDir.uri.resolve('my_custom_main.dart');

      final originalCode = await File.fromUri(
        dartAppUri.resolve('bin/dart_app.dart'),
      ).readAsString();
      await File.fromUri(customEntryPoint).writeAsString(originalCode);

      // 2. Relocate the package config and package graph to a custom directory matching same depth
      final customToolDir =
          Directory.fromUri(dartAppUri.resolve('.custom_tool/'));
      await customToolDir.create();

      final originalConfig = File.fromUri(
        dartAppUri.resolve('.dart_tool/package_config.json'),
      );
      final customConfig = File.fromUri(
        customToolDir.uri.resolve('my_custom_packages.json'),
      );
      await originalConfig.copy(customConfig.path);

      final originalGraph = File.fromUri(
        dartAppUri.resolve('.dart_tool/package_graph.json'),
      );
      final customGraph = File.fromUri(
        customToolDir.uri.resolve('package_graph.json'),
      );
      await originalGraph.copy(customGraph.path);

      // 3. Invoke build using the custom arguments
      final result = await runDart(
        arguments: [
          'build',
          'cli',
          '--packages=${customConfig.path}',
          '--target=${customEntryPoint.toFilePath()}',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
      );

      expect(result.stdout, contains('Running build hooks'));
      expect(result.stdout, contains('Running link hooks'));

      // 4. Verify the executable runs correctly and prints expected output
      final relativeExeUri = relativeBundleUri
          .resolve('bin/')
          .resolve(OS.current.executableFileName('my_custom_main'));
      final absoluteExeUri = dartAppUri.resolveUri(relativeExeUri);
      expect(await File.fromUri(absoluteExeUri).exists(), true);

      final processResult = await runProcess(
        executable: absoluteExeUri,
        logger: logger,
        throwOnUnexpectedExitCode: true,
      );
      expectDartAppStdout(processResult.stdout);
    });
  });

  test('dart build cli unmapped entrypoint aborts', timeout: longTimeout,
      () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      await runPubGet(workingDirectory: dartAppUri, logger: logger);

      // Create an entry point outside the project structure (isolated temp dir)
      await _withTempDir((tempUri) async {
        final isolatedEntryPoint = tempUri.resolve('isolated.dart');
        await File.fromUri(isolatedEntryPoint).writeAsString('''
void main() {
  print('Hello isolated');
}
''');

        // Invoke build pointing to the isolated file
        final result = await runDart(
          arguments: [
            'build',
            'cli',
            '--packages=${dartAppUri.resolve('.dart_tool/package_config.json').toFilePath()}',
            '--target=${isolatedEntryPoint.toFilePath()}',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
          expectExitCodeZero: false,
        );

        expect(
          result.stderr,
          contains(
              'does not reside in any package defined in the package config'),
        );
        expect(result.exitCode, 255);
      });
    });
  });

  test('dart build cli unmapped entrypoint succeeds with --root-package',
      timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      await runPubGet(workingDirectory: dartAppUri, logger: logger);

      // Create an entry point outside the project structure (isolated temp dir)
      await _withTempDir((tempUri) async {
        final isolatedEntryPoint = tempUri.resolve('isolated.dart');
        await File.fromUri(isolatedEntryPoint).writeAsString('''
void main() {
  print('Hello isolated');
}
''');

        // Invoke build pointing to the isolated file with --root-package
        final result = await runDart(
          arguments: [
            'build',
            'cli',
            '--packages=${dartAppUri.resolve('.dart_tool/package_config.json').toFilePath()}',
            '--target=${isolatedEntryPoint.toFilePath()}',
            '--root-package=dart_app',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
          expectExitCodeZero: true,
        );

        expect(result.stdout, contains('Running build hooks'));
        expect(result.stdout, contains('Running link hooks'));

        // Verify the executable runs correctly and prints expected output
        final relativeExeUri = relativeBundleUri
            .resolve('bin/')
            .resolve(OS.current.executableFileName('isolated'));
        final absoluteExeUri = dartAppUri.resolveUri(relativeExeUri);
        expect(await File.fromUri(absoluteExeUri).exists(), true);

        final processResult = await runProcess(
          executable: absoluteExeUri,
          logger: logger,
          throwOnUnexpectedExitCode: true,
        );
        expect(processResult.stdout, contains('Hello isolated'));
      });
    });
  });

  test(
    'dart build cli cross compilation to linux (no build)',
    timeout: longTimeout,
    () async {
      await _runDownloadHookAppTest((dartAppUri) async {
        final result = await runDart(
          arguments: [
            'build',
            'cli',
            '--target-os',
            'linux',
            '--target-arch',
            'x64',
          ],
          workingDirectory: dartAppUri,
          logger: logger,
        );

        expect(result.stdout, contains('Running build hooks'));
        final bundleDirectory = Directory.fromUri(
          dartAppUri.resolve('build/cli/linux_x64/bundle/'),
        );
        expect(bundleDirectory.existsSync(), isTrue);

        final libDirectory = Directory.fromUri(
          bundleDirectory.uri.resolve('lib/'),
        );
        expect(libDirectory.existsSync(), isTrue);

        final dylib = File.fromUri(
          libDirectory.uri.resolve('libdart_app_download_hook.so'),
        );
        expect(dylib.existsSync(), isTrue);
        expect(
          await dylib.readAsString(),
          'simulated downloaded asset for dart_app_download_hook',
        );
      });
    },
  );
}

Future<void> _runDownloadHookAppTest(
  Future<void> Function(Uri appUri) fun,
) async {
  await inTempDir((tempUri) async {
    final sourceAppUri = sdkRootUri.resolve(
      'pkg/dartdev/test/data/dart_app_download_hook/',
    );
    final targetAppUri = tempUri.resolve('dart_app_download_hook/');
    final targetAppDir = Directory.fromUri(targetAppUri);
    await copyDirectory(Directory.fromUri(sourceAppUri), targetAppDir);

    final pubspecFile = File.fromUri(targetAppUri.resolve('pubspec.yaml'));
    final pubspecString = await pubspecFile.readAsString();
    final pubspec = YamlEditor(pubspecString);
    pubspec.update([
      'dependency_overrides'
    ], {
      'code_assets': {
        'path': sdkRootUri
            .resolve('third_party/pkg/native/pkgs/code_assets/')
            .toFilePath(),
      },
      'hooks': {
        'path': sdkRootUri
            .resolve('third_party/pkg/native/pkgs/hooks/')
            .toFilePath(),
      },
      // Include package:record_use in dependency_overrides alongside hooks so
      // unreleased record_use versions required by package:hooks are resolved
      // directly from the local SDK checkout rather than pub.dev.
      'record_use': {
        'path': sdkRootUri
            .resolve('third_party/pkg/native/pkgs/record_use/')
            .toFilePath(),
      },
    });
    await pubspecFile.writeAsString(pubspec.toString());

    await fun(targetAppUri);
  });

  // TODO(https://github.com/dart-lang/native/pull/3427): Add a test for C cross
  // compilation. You may want to create a new test application and
  // generalize `_runDownloadHookAppTest` to work with it.
}

Future<void> _withTempDir(Future<void> Function(Uri tempUri) fun) async {
  final tempDir = await Directory.systemTemp.createTemp('link_dir');
  final tempDirResolved = Directory(await tempDir.resolveSymbolicLinks());
  try {
    await fun(tempDirResolved.uri);
  } finally {
    if (!Platform.environment.containsKey(keepTempKey) ||
        Platform.environment[keepTempKey]!.isEmpty) {
      await tempDirResolved.delete(recursive: true);
    }
  }
}

Uri removeDotExe(Uri withExe) {
  final exeName = withExe.pathSegments.lastWhere((e) => e.isNotEmpty);
  if (!exeName.endsWith('.exe')) {
    throw StateError('Expected executable to end in .exe, got $exeName');
  }
  final fileName = exeName.replaceAll('.exe', '');
  return withExe.resolve(fileName);
}

String _linuxAotSnapshotFileName(String executableName) =>
    'libdartaot$executableName.so';
