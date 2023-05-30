// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!isAOTRuntime) {
    print('Skipping test due to AOT runtime not being available');
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    print('Skipping test due to being on Android where needed tools are not '
        'available.');
    return; // SDK tree and gen_snapshot not available on the test device.
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

  await withElfSnapshot((Elf elf) {
    // NOTE: These tests validate properties we should strive to maintain.
    // Please reach out to go/dart-ama before changing them.
    final Symbol? symbol =
        elf.dynamicSymbolFor('_kDartIsolateSnapshotInstructions');
    Expect.isTrue(symbol != null && symbol.value > 0);
  });
}

Future withElfSnapshot(Function(Elf) fun) async {
  await withTempDir('ama-test', (String tempDir) async {
    final scriptDart = path.join(tempDir, 'script.dart');
    final scriptDill = path.join(tempDir, 'script.dill');
    final scriptElf = path.join(tempDir, 'script.elf');
    File(scriptDart).writeAsStringSync('main() => print("script");');

    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      scriptDart,
    ]);

    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-elf',
      '--elf=$scriptElf',
      scriptDill,
    ]);

    final elf = Elf.fromFile(scriptElf)!;
    await fun(elf);
  });
}
