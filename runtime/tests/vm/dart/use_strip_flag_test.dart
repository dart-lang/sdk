// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that the AOT compiler can generate stripped versions of
// ELF and assembly output. This test is currently very weak, in that it just
// checks that the stripped version is strictly smaller than the unstripped one.

// OtherResources=use_dwarf_stack_traces_flag_program.dart

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

  await withTempDir('strip-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    // We can just reuse the program for the use_dwarf_stack_traces test.
    final script = path.join(cwDir, 'use_dwarf_stack_traces_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    // Run the AOT compiler to generate stripped and unstripped ELF snapshots.
    final unstrippedSnapshot = path.join(tempDir, 'whole.so');
    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-elf',
      '--elf=$unstrippedSnapshot',
      scriptDill,
    ]);

    final strippedSnapshot = path.join(tempDir, 'stripped.so');
    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-elf',
      '--elf=$strippedSnapshot',
      '--strip',
      scriptDill,
    ]);

    compareStrippedAndUnstripped(
        stripped: strippedSnapshot, unstripped: unstrippedSnapshot);

    if (Platform.isWindows) {
      return; // No assembly generation on Windows.
    }

    final unstrippedCode = path.join(tempDir, 'whole.S');
    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-assembly',
      '--assembly=$unstrippedCode',
      scriptDill,
    ]);

    final strippedCode = path.join(tempDir, 'stripped.S');
    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-assembly',
      '--assembly=$strippedCode',
      '--strip',
      scriptDill,
    ]);

    compareStrippedAndUnstripped(
        stripped: strippedCode, unstripped: unstrippedCode);
  });
}

void compareStrippedAndUnstripped({String stripped, String unstripped}) {
  final strippedSize = File(stripped).lengthSync();
  final unstrippedSize = File(unstripped).lengthSync();
  print("File size for stripped file $stripped: $strippedSize");
  print("File size for stripped file $unstripped: $unstrippedSize");
  Expect.isTrue(strippedSize < unstrippedSize);
}
