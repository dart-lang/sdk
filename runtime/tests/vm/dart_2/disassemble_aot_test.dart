// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=hello_world_test.dart
//
// Tests proper object recognition in disassembler.

// @dart = 2.9

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

Future<void> main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (const bool.fromEnvironment('dart.vm.product')) {
    return; // No disassembling in PRODUCT mode.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }
  if (!await testExecutable(dartPrecompiledRuntime)) {
    throw "Cannot run test as $dartPrecompiledRuntime not available";
  }
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }

  await withTempDir('disassemble_aot', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script = path.join(cwDir, 'hello_world_test.dart');
    final scriptDill = path.join(tempDir, 'out.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--no-sound-null-safety',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    // Run the AOT compiler with the disassemble flags set.
    final elfFile = path.join(tempDir, 'aot.snapshot');
    await run(genSnapshot, <String>[
      '--disassemble',
      '--disassemble_stubs',
      '--no-sound-null-safety',
      '--always_generate_trampolines_for_testing',
      '--snapshot-kind=app-aot-elf',
      '--elf=$elfFile',
      scriptDill
    ]);

    // Run the AOT runtime with the disassemble flags set.
    await run(dartPrecompiledRuntime,
        <String>['--disassemble', '--disassemble_stubs', elfFile]);
  });
}
