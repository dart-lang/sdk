// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is ensuring that the flag for --use-bare-instructions given at
// AOT compile-time will be used at runtime (irrespective if other values were
// passed to the runtime).

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
  }

  await withTempDir('bare-flag-test', (String tempDir) async {
    final script = path.join(sdkDir, 'pkg/kernel/bin/dump.dart');
    final scriptDill = path.join(tempDir, 'kernel_dump.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    // Run the AOT compiler with/without bare instructions.
    final scriptBareSnapshot = path.join(tempDir, 'bare.snapshot');
    final scriptNonBareSnapshot = path.join(tempDir, 'non_bare.snapshot');
    await Future.wait(<Future>[
      run(genSnapshot, <String>[
        '--use-bare-instructions',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptBareSnapshot',
        scriptDill,
      ]),
      run(genSnapshot, <String>[
        '--no-use-bare-instructions',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptNonBareSnapshot',
        scriptDill,
      ]),
    ]);

    // Run the resulting bare-AOT compiled script.
    final bareOut1 = path.join(tempDir, 'bare-out1.txt');
    final bareOut2 = path.join(tempDir, 'bare-out2.txt');
    await Future.wait(<Future>[
      run(aotRuntime, <String>[
        '--use-bare-instructions',
        scriptBareSnapshot,
        scriptDill,
        bareOut1,
      ]),
      run(aotRuntime, <String>[
        '--no-use-bare-instructions',
        scriptBareSnapshot,
        scriptDill,
        bareOut2,
      ]),
    ]);

    // Run the resulting non-bare-AOT compiled script.
    final nonBareOut1 = path.join(tempDir, 'non-bare-out1.txt');
    final nonBareOut2 = path.join(tempDir, 'non-bare-out2.txt');
    await Future.wait(<Future>[
      run(aotRuntime, <String>[
        '--use-bare-instructions',
        scriptNonBareSnapshot,
        scriptDill,
        nonBareOut1,
      ]),
      run(aotRuntime, <String>[
        '--no-use-bare-instructions',
        scriptNonBareSnapshot,
        scriptDill,
        nonBareOut2,
      ]),
    ]);

    // Ensure we got 4 times the same result.
    final output = await readFile(bareOut1);
    Expect.equals(output, await readFile(bareOut2));
    Expect.equals(output, await readFile(nonBareOut1));
    Expect.equals(output, await readFile(nonBareOut2));
  });
}

Future<String> readFile(String file) {
  return new File(file).readAsString();
}
