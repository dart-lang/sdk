// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the compact unwinding information is appropriately
// generated for Mac ARM64 snapshots.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/src/dwarf_container.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

Future<void> main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  // Currently, this test only checks compact unwinding information, which
  // is only generated on Mac ARM64 binaries.
  if (!Platform.isMacOS || !buildDir.endsWith('ARM64')) {
    return;
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

  await withTempDir('unwinding-information', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script = path.join(
      cwDir,
      'use_save_debugging_info_flag_program.dart',
    );
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    await checkMachO(tempDir, scriptDill);
  });
}

Future<List<String>> retrieveUnwindInfo(
  SnapshotType snapshotType,
  String snapshotPath,
) async {
  if (snapshotType != SnapshotType.machoDylib) {
    throw ArgumentError("Unhandled snapshot type");
  }
  final objdump = llvmTool('llvm-objdump');
  if (objdump == null) {
    throw StateError('Expected llvm-objdump in buildutils');
  }
  return await runOutput(objdump, ['--macho', '-u', snapshotPath]);
}

Future<void> checkSnapshotType(
  String tempDir,
  String scriptDill,
  SnapshotType snapshotType,
) async {
  final scriptUnstrippedSnapshot = path.join(
    tempDir,
    'unstripped-$snapshotType.so',
  );
  await createSnapshot(scriptDill, snapshotType, scriptUnstrippedSnapshot);
  final unstrippedCase = TestCase(
    snapshotType,
    scriptUnstrippedSnapshot,
    snapshotType.fromFile(scriptUnstrippedSnapshot)!,
    await retrieveUnwindInfo(snapshotType, scriptUnstrippedSnapshot),
  );

  final scriptStrippedSnapshot = path.join(
    tempDir,
    'stripped-$snapshotType.so',
  );
  await createSnapshot(scriptDill, snapshotType, scriptStrippedSnapshot, [
    '--strip',
  ]);
  final strippedCase = TestCase(
    snapshotType,
    scriptStrippedSnapshot,
    snapshotType.fromFile(scriptStrippedSnapshot)!,
    await retrieveUnwindInfo(snapshotType, scriptStrippedSnapshot),
  );

  checkCases(unstrippedCase, strippedCase);
}

Future<void> checkMachO(String tempDir, String scriptDill) async {
  await checkSnapshotType(tempDir, scriptDill, SnapshotType.machoDylib);
}

class TestCase {
  final SnapshotType snapshotType;
  final String snapshotPath;
  final DwarfContainer container;
  final List<String> unwindInfo;

  TestCase(
    this.snapshotType,
    this.snapshotPath,
    this.container,
    this.unwindInfo,
  );
}

void checkCases(TestCase unstripped, TestCase stripped) {
  Expect.isNotEmpty(unstripped.unwindInfo);
  Expect.deepEquals(unstripped.unwindInfo, stripped.unwindInfo);
}
