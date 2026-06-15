// Copyright 2022 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO: The examples don't work on windows
@TestOn('!windows')
library;

import 'dart:io';

import 'package:frontend_server_client/src/package_config_utils.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

void main() {
  test('web client example can build and rebuild an app', () async {
    // Resolve the example script path based on the package root.
    final exampleFilePath = await pathFromNearestPackageConfig(
      'example/web_client.dart',
    );
    final process = await TestProcess.start(Platform.resolvedExecutable, [
      'run',
      exampleFilePath,
    ]);
    await expectLater(
      process.stdout,
      emitsThrough(contains('done compiling example/app/main.dart')),
    );
    process.stdin.writeln('new message');
    await expectLater(
      process.stdout,
      emitsThrough(contains('Recompile succeeded for example/app/main.dart')),
    );
    process.stdin.writeln('quit');
    expect(await process.exitCode, 0);
  });
}
