// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that using an AbiSpecificInteger with an incomplete mapping produces
// a compile-time error during AOT compilation.
//
// Uses pkg/vm/tool/gen_kernel and the build directory's gen_snapshot rather
// than `dart compile aot-snapshot`, because the test bots do not build the
// full SDK (gen_kernel_aot.dart.snapshot).

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

final _execSuffix = Platform.isWindows ? '.exe' : '';
final _batSuffix = Platform.isWindows ? '.bat' : '';

String _findGenSnapshot(String buildDir) {
  final possiblePaths = [
    // No cross compilation.
    path.join(buildDir, 'gen_snapshot$_execSuffix'),
    // ${MODE}SIMARM_X64 for X64->SIMARM cross compilation.
    path.join('${buildDir}_X64', 'gen_snapshot$_execSuffix'),
    // ${MODE}XARM64/clang_x64 for X64->ARM64 cross compilation.
    path.join(buildDir, 'clang_x64', 'gen_snapshot$_execSuffix'),
  ];
  for (final p in possiblePaths) {
    if (File(p).existsSync()) {
      return p;
    }
  }
  throw 'Could not find gen_snapshot for build directory $buildDir';
}

void main() {
  final buildDir = path.dirname(Platform.executable);
  final sdkDir = path.dirname(path.dirname(buildDir));
  final genKernel = path.join(
    sdkDir,
    'pkg',
    'vm',
    'tool',
    'gen_kernel$_batSuffix',
  );
  final genSnapshot = _findGenSnapshot(buildDir);
  final platformDill = path.join(buildDir, 'vm_platform.dill');
  final helperPath = path.join(
    sdkDir,
    'tests',
    'ffi',
    'abi_specific_int_incomplete_aot_test_helper.dart',
  );

  final tempDir = Directory.systemTemp.createTempSync('abi_incomplete_aot');
  try {
    final dillPath = path.join(tempDir.path, 'out.dill');

    // Compiling the helper to kernel should succeed; the incomplete ABI
    // mapping is only detected by the VM precompiler.
    final kernelResult = Process.runSync(genKernel, [
      '--aot',
      '--platform=$platformDill',
      '-o',
      dillPath,
      helperPath,
    ]);
    Expect.equals(
      0,
      kernelResult.exitCode,
      'gen_kernel failed: ${kernelResult.stdout}\n${kernelResult.stderr}',
    );

    // AOT compiling the kernel file should fail with a compile-time error
    // about the incomplete ABI mapping.
    final snapshotResult = Process.runSync(genSnapshot, [
      '--snapshot-kind=app-aot-elf',
      '--elf=${path.join(tempDir.path, 'out.so')}',
      dillPath,
    ]);
    Expect.notEquals(0, snapshotResult.exitCode);
    final stderr = snapshotResult.stderr.toString();
    Expect.isTrue(
      stderr.contains("AbiSpecificInteger 'Incomplete' is missing mapping for"),
      'Expected error about missing ABI mapping, got: $stderr',
    );
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
