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
  test('vm client example can build and rebuild an app', () async {
    // Resolve the example script path based on the package root.
    final exampleFilePath = await pathFromNearestPackageConfig(
      'example/vm_client.dart',
    );
    final process = await TestProcess.start(Platform.resolvedExecutable, [
      'run',
      exampleFilePath,
    ]);
    await expectLater(
      process.stdout,
      emitsThrough(contains('done compiling example/app/main.dart')),
    );
    await expectLater(
      process.stdout,
      emitsThrough(contains('APP -> hello/world')),
    );
    await expectLater(
      process.stdout,
      emitsThrough(contains('done recompiling example/app/main.dart')),
    );
    await expectLater(
      process.stdout,
      emitsThrough(contains('APP -> goodbye/world')),
    );
    expect(await process.exitCode, 0);
  });
}
