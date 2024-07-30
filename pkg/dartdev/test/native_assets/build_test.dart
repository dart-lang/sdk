// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

import 'package:native_assets_cli/native_assets_cli_internal.dart';
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

void main(List<String> args) async {
  final bool fromDartdevSource = args.contains('--source');
  final hostOS = Platform.operatingSystem;
  final crossOS = Platform.isLinux ? 'macos' : 'linux';
  for (final targetOS in [null, hostOS, crossOS]) {
    String? osModifier;
    if (targetOS == hostOS) {
      osModifier = 'host';
    } else if (targetOS == crossOS) {
      osModifier = 'cross';
    }
    for (final verbose in [true, false]) {
      final testModifier = [
        '',
        if (osModifier != null) osModifier,
        if (verbose) 'verbose'
      ].join(' ');
      test('dart build$testModifier', timeout: longTimeout, () async {
        await nativeAssetsTest('dart_app', (dartAppUri) async {
          final bool expectCrossOSFailure = targetOS == crossOS;
          final result = await runDart(
            arguments: [
              '--enable-experiment=native-assets',
              if (fromDartdevSource)
                Platform.script.resolve('../../bin/dartdev.dart').toFilePath(),
              'build',
              if (targetOS != null) ...[
                '--target-os',
                targetOS,
              ],
              if (verbose) '-v',
              'bin/dart_app.dart',
            ],
            workingDirectory: dartAppUri,
            logger: logger,
            expectExitCodeZero: !expectCrossOSFailure,
          );
          if (expectCrossOSFailure) {
            expect(result.stderr, contains(crossOSNotAllowedError('exe')));
            expect(result.stderr, contains(hostOSMessage));
            expect(result.stderr, contains(targetOSMessage(crossOS)));
            expect(result.exitCode, 128);
            return; // No executable to run.
          }
          if (verbose) {
            expect(result.stdout, contains(usingTargetOSMessage));
            expect(result.stdout, contains('build.dart'));
          } else {
            expect(result.stdout, isNot(contains('build.dart')));
          }

          final relativeExeUri = Uri.file('./bin/dart_app/dart_app.exe');
          final absoluteExeUri = dartAppUri.resolveUri(relativeExeUri);
          expect(await File.fromUri(absoluteExeUri).exists(), true);
          await _withTempDir((tempUri) async {
            // The link needs to have the same extension as the executable on
            // Windows to be able to be executable.
            final link = Link.fromUri(tempUri.resolve('my_link.exe'));
            await link.create(absoluteExeUri.toFilePath());
            for (final exeUri in [
              absoluteExeUri,
              relativeExeUri,
              link.uri,
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
          '--enable-experiment=native-assets',
          'build',
          'bin/dart_app.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.stderr,
        contains(
          'Native assets build failed.',
        ),
      );
      expect(result.exitCode, 255);
    });
  });

  test('dart link assets', timeout: longTimeout, () async {
    await nativeAssetsTest('drop_dylib_link', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          '--enable-experiment=native-assets',
          'build',
          'bin/drop_dylib_link.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(result.exitCode, 0);

      // Check that the build directory exists
      final directory =
          Directory.fromUri(dartAppUri.resolve('bin/drop_dylib_link'));
      expect(directory.existsSync(), true);

      // Check that only one dylib is in the final application package
      final buildFiles = directory.listSync(recursive: true);
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
          '--enable-experiment=native-assets',
          'build',
          'bin/add_asset_link.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(result.exitCode, 0);

      // Check that the build directory exists
      final directory =
          Directory.fromUri(dartAppUri.resolve('bin/add_asset_link'));
      expect(directory.existsSync(), true);
      final dylib =
          OSImpl.current.libraryFileName('add', DynamicLoadingBundledImpl());
      expect(
        File.fromUri(directory.uri.resolve('lib/$dylib')).existsSync(),
        true,
      );
    });
  });
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
