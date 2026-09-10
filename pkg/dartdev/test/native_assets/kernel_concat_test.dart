// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/native_assets.dart';
import 'package:dartdev/src/resident_frontend_utils.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('compileNativeAssetsToDill', () {
    test('compiles native_assets.yaml to dill', () async {
      await inTempDir((tempUri) async {
        final nativeAssetsYaml = File.fromUri(
          tempUri.resolve('native_assets.yaml'),
        );
        await nativeAssetsYaml.writeAsString('''
format-version:
  - 1
  - 0
  - 0
native-assets: {}
''');
        final outputDill = tempUri.resolve('output.dill');
        final success = await compileNativeAssetsToDill(
          nativeAssetsYamlUri: nativeAssetsYaml.uri,
          outputDillUri: outputDill,
        );
        expect(success, isTrue);

        final outputFile = File.fromUri(outputDill);
        expect(await outputFile.exists(), isTrue);
        expect(await isFileKernelFile(outputFile), isTrue);
      });
    });

    test('returns false when native assets compilation fails', () async {
      await inTempDir((tempUri) async {
        final nonExistentYaml = tempUri.resolve('does_not_exist.yaml');
        final outputDill = tempUri.resolve('output.dill');
        final success = await compileNativeAssetsToDill(
          nativeAssetsYamlUri: nonExistentYaml,
          outputDillUri: outputDill,
        );
        expect(success, isFalse);
      });
    });
  });

  group('concatenateNativeAssetsKernel', () {
    test('concatenates kernel file with native assets dill', () async {
      await inTempDir((tempUri) async {
        final dummyKernelFile = File.fromUri(tempUri.resolve('original.dill'));
        // Kernel magic number: 0x90, 0xab, 0xcd, 0xef
        final dummyKernelBytes = [0x90, 0xab, 0xcd, 0xef, 1, 2, 3, 4, 5];
        await dummyKernelFile.writeAsBytes(dummyKernelBytes);

        final nativeAssetsYaml = File.fromUri(
          tempUri.resolve('native_assets.yaml'),
        );
        await nativeAssetsYaml.writeAsString('''
format-version:
  - 1
  - 0
  - 0
native-assets: {}
''');

        final concatenatedPath = await concatenateNativeAssetsKernel(
          kernelFilePath: dummyKernelFile.path,
          nativeAssetsYamlUri: nativeAssetsYaml.uri,
          tempDirUri: tempUri,
        );
        expect(concatenatedPath, isNotNull);

        final concatenatedFile = File(concatenatedPath!);
        expect(await concatenatedFile.exists(), isTrue);

        final concatenatedBytes = await concatenatedFile.readAsBytes();
        final nativeAssetsDill = File.fromUri(
          tempUri.resolve('native_assets.dill'),
        );
        expect(await nativeAssetsDill.exists(), isTrue);
        final nativeAssetsBytes = await nativeAssetsDill.readAsBytes();

        expect(
          concatenatedBytes.length,
          equals(dummyKernelBytes.length + nativeAssetsBytes.length),
        );
        expect(
          concatenatedBytes.sublist(0, dummyKernelBytes.length),
          equals(dummyKernelBytes),
        );
        expect(
          concatenatedBytes.sublist(dummyKernelBytes.length),
          equals(nativeAssetsBytes),
        );
      });
    });

    test(
      'updating native assets between concatenations updates output while preserving base kernel',
      () async {
        await inTempDir((tempUri) async {
          final baseKernelFile = File.fromUri(tempUri.resolve('base.dill'));
          final baseKernelBytes = [0x90, 0xab, 0xcd, 0xef, 10, 20, 30, 40];
          await baseKernelFile.writeAsBytes(baseKernelBytes);

          final run1TempDir = Directory.fromUri(tempUri.resolve('run1/'));
          await run1TempDir.create();
          final nativeAssetsYaml1 = File.fromUri(
            run1TempDir.uri.resolve('native_assets.yaml'),
          );
          await nativeAssetsYaml1.writeAsString('''
format-version:
  - 1
  - 0
  - 0
native-assets:
  linux_x64:
    foo:
      - system
      - libfoo.so
''');

          final concatenatedPath1 = await concatenateNativeAssetsKernel(
            kernelFilePath: baseKernelFile.path,
            nativeAssetsYamlUri: nativeAssetsYaml1.uri,
            tempDirUri: run1TempDir.uri,
          );
          expect(concatenatedPath1, isNotNull);
          final bytes1 = await File(concatenatedPath1!).readAsBytes();

          final run2TempDir = Directory.fromUri(tempUri.resolve('run2/'));
          await run2TempDir.create();
          final nativeAssetsYaml2 = File.fromUri(
            run2TempDir.uri.resolve('native_assets.yaml'),
          );
          await nativeAssetsYaml2.writeAsString('''
format-version:
  - 1
  - 0
  - 0
native-assets:
  linux_x64:
    bar:
      - system
      - libbar.so
''');

          final concatenatedPath2 = await concatenateNativeAssetsKernel(
            kernelFilePath: baseKernelFile.path,
            nativeAssetsYamlUri: nativeAssetsYaml2.uri,
            tempDirUri: run2TempDir.uri,
          );
          expect(concatenatedPath2, isNotNull);
          final bytes2 = await File(concatenatedPath2!).readAsBytes();

          // Both start with the same base kernel bytes.
          expect(
            bytes1.sublist(0, baseKernelBytes.length),
            equals(baseKernelBytes),
          );
          expect(
            bytes2.sublist(0, baseKernelBytes.length),
            equals(baseKernelBytes),
          );

          // But the native assets portions differ, reflecting the update.
          expect(
            bytes1.sublist(baseKernelBytes.length),
            isNot(equals(bytes2.sublist(baseKernelBytes.length))),
          );
        });
      },
    );

    test('returns null when native assets compilation fails', () async {
      await inTempDir((tempUri) async {
        final dummyKernelFile = File.fromUri(tempUri.resolve('original.dill'));
        await dummyKernelFile.writeAsBytes([0x90, 0xab, 0xcd, 0xef, 1, 2, 3]);

        final nonExistentYaml = tempUri.resolve('does_not_exist.yaml');
        final result = await concatenateNativeAssetsKernel(
          kernelFilePath: dummyKernelFile.path,
          nativeAssetsYamlUri: nonExistentYaml,
          tempDirUri: tempUri,
        );
        expect(result, isNull);
      });
    });
  });
}
