// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64990.
//
// Writing a V8 snapshot profile used to abort when a canonical constant that
// was only referenced by a weakened constants table, here a closure, needed
// an artificial node in the profile.

// OtherResources=regress_64990_program.dart

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

  await withTempDir('regress_64990_test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script = path.join(cwDir, 'regress_64990_program.dart');
    final scriptDill = path.join(tempDir, 'regress_64990_program.dill');

    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    final profile = path.join(tempDir, 'profile.json');
    final snapshot = path.join(tempDir, 'snapshot.so');
    await run(genSnapshot, <String>[
      if (Platform.isMacOS) ...[
        '--snapshot-kind=app-aot-macho-dylib',
        '--macho=$snapshot',
      ] else ...[
        '--snapshot-kind=app-aot-elf',
        '--elf=$snapshot',
      ],
      '--write-v8-snapshot-profile-to=$profile',
      scriptDill,
    ]);
    Expect.isTrue(File(profile).existsSync());

    final output = await runOutput(dartPrecompiledRuntime, [snapshot]);
    Expect.listEquals(["Instance of 'Holder'", "Instance of 'Holder'"], output);
  });
}
