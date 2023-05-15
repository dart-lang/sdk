// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main(List<String> args) async {
  test('cached build', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      await runPubGet(
        workingDirectory: packageUri,
        logger: logger,
      );

      {
        final logMessages = <String>[];
        await build(packageUri, logger, dartExecutable,
            capturedLogs: logMessages);
        expect(
            logMessages.join('\n'),
            stringContainsInOrder(
                ['native_add${Platform.pathSeparator}build.dart']));
      }

      {
        final logMessages = <String>[];
        await build(packageUri, logger, dartExecutable,
            capturedLogs: logMessages);
        expect(logMessages.join('\n'),
            stringContainsInOrder(['Skipping build for native_add']));
        expect(
            false,
            logMessages
                .join('\n')
                .contains('native_add${Platform.pathSeparator}build.dart'));
      }
    });
  });

  test('modify C file', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      await runPubGet(
        workingDirectory: packageUri,
        logger: logger,
      );

      {
        final assets = await build(packageUri, logger, dartExecutable);
        await expectSymbols(asset: assets.single, symbols: ['add']);
      }

      await copyTestProjects(
        sourceUri: testProjectsUri.resolve('native_add_add_symbol/'),
        targetUri: packageUri,
      );

      {
        final assets = await build(packageUri, logger, dartExecutable);
        await expectSymbols(asset: assets.single, symbols: ['add', 'subtract']);
      }
    });
  });

  test('add C file, modify script', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      await runPubGet(workingDirectory: packageUri, logger: logger);

      {
        final assets = await build(packageUri, logger, dartExecutable);
        await expectSymbols(asset: assets.single, symbols: ['add']);
      }

      await copyTestProjects(
          sourceUri: testProjectsUri.resolve('native_add_add_source/'),
          targetUri: packageUri);

      {
        final assets = await build(packageUri, logger, dartExecutable);
        await expectSymbols(asset: assets.single, symbols: ['add', 'multiply']);
      }
    });
  });
}
