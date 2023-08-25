// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

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
          for (final exeUri in [absoluteExeUri, relativeExeUri]) {
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
    }
  }
}
