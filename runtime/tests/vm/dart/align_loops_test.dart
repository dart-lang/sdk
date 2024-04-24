// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

void checkAligned(Symbol sym) {
  // We only expect to run this test on X64 Linux.
  final expectedAlignment = 32;
  if ((sym.value & (expectedAlignment - 1)) != 0) {
    throw 'Symbol $sym has value ${sym.value} which is not aligned by '
        '$expectedAlignment';
  }
}

Future<void> testAOT(String dillPath, {bool useAsm = false}) async {
  await withTempDir('align-loops-test-${useAsm ? 'asm' : 'elf'}',
      (String tempDir) async {
    // Generate the snapshot
    final snapshotPath = path.join(tempDir, 'libtest.so');
    final commonSnapshotArgs = [dillPath];

    if (useAsm) {
      final assemblyPath = path.join(tempDir, 'test.S');

      await run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-assembly',
        '--assembly=$assemblyPath',
        ...commonSnapshotArgs,
      ]);

      await assembleSnapshot(assemblyPath, snapshotPath);
    } else {
      await run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-elf',
        '--elf=$snapshotPath',
        ...commonSnapshotArgs,
      ]);
    }

    print("Snapshot generated at $snapshotPath.");

    final elf = Elf.fromFile(snapshotPath)!;
    // The very first symbol should be aligned by 32 bytes because it is
    // the start of the instructions section.
    checkAligned(elf.staticSymbols.first);
    for (var symbol in elf.staticSymbols) {
      if (symbol.name.startsWith('alignedFunction')) {
        checkAligned(symbol);
      }
    }
  });
}

void main() async {
  // Only run this test on Linux X64 for simplicity.
  if (!(Platform.isLinux && buildDir.endsWith('X64'))) {
    return;
  }

  await withTempDir('align_loops', (String tempDir) async {
    final testProgram = path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
        'align_loops_test_program.dart');

    final aotDillPath = path.join(tempDir, 'aot_test.dill');
    await run(genKernel, <String>[
      '--aot',
      '--platform',
      platformDill,
      ...Platform.executableArguments
          .where((arg) => arg.startsWith('--enable-experiment=')),
      '-o',
      aotDillPath,
      testProgram
    ]);

    await Future.wait([
      // Test unstripped ELF generation directly.
      testAOT(aotDillPath),
      testAOT(aotDillPath, useAsm: true),
    ]);
  });
}
