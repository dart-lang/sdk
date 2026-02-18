// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

String usingTargetOSMessageForPlatform(String targetOS) =>
    'Specializing Platform getters for target OS $targetOS.';
final String usingTargetOSMessage =
    usingTargetOSMessageForPlatform(Platform.operatingSystem);
String crossOSNotAllowedError(String format) =>
    "'dart build -f $format' does not support cross-OS compilation.";
final String hostOSMessage = 'Host OS: ${Platform.operatingSystem}';
String targetOSMessage(String targetOS) => 'Target OS: $targetOS';

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
