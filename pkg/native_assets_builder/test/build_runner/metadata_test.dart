// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main(List<String> args) async {
  test('get dependency metadata', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('package_reading_metadata/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(
        workingDirectory: packageUri,
        logger: logger,
      );

      // Trigger a build, should invoke build for libraries with native assets.
      {
        final logMessages = <String>[];
        await build(packageUri, logger, dartExecutable,
            capturedLogs: logMessages);
        expect(
            logMessages.join('\n'),
            stringContainsInOrder([
              'package_with_metadata${Platform.pathSeparator}build.dart',
              'package_reading_metadata${Platform.pathSeparator}build.dart',
              '{some_int: 3, some_key: some_value}',
            ]));
      }
    });
  });
}
