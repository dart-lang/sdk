// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/169921.

// OtherResources=regress_flutter169921_program.dart
// OtherResources=regress_flutter169921_deferred.dart

import "dart:io";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }

  await withTempDir('regress_flutter169921_test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script = path.join(cwDir, 'regress_flutter169921_program.dart');
    final scriptDill = path.join(tempDir, 'regress_flutter169921_program.dill');

    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    final manifest = path.join(tempDir, 'manifest.json');
    final profile = path.join(tempDir, 'profile.json');
    final snapshot = path.join(tempDir, 'snapshot.so');
    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-elf',
      '--elf=$snapshot',
      '--loading-unit-manifest=$manifest',
      '--write-v8-snapshot-profile-to=$profile',
      scriptDill,
    ]);

    await runError(dartPrecompiledRuntime, [snapshot], printStderr: true);
  });
}
