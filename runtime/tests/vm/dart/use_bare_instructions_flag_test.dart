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

main(List<String> args) async {
  if (!Platform.executable.endsWith("dart_precompiled_runtime")) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
  }

  final buildDir = path.dirname(Platform.executable);
  final sdkDir = path.dirname(path.dirname(buildDir));
  final platformDill = path.join(buildDir, 'vm_platform_strong.dill');
  final genSnapshot = path.join(buildDir, 'gen_snapshot');
  final aotRuntime = path.join(buildDir, 'dart_precompiled_runtime');

  await withTempDir((String tempDir) async {
    final script = path.join(sdkDir, 'pkg/kernel/bin/dump.dart');
    final scriptDill = path.join(tempDir, 'kernel_dump.dill');

    // Compile script to Kernel IR.
    await run('pkg/vm/tool/gen_kernel', <String>[
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

Future run(String executable, List<String> args) async {
  print('Running $executable ${args.join(' ')}');

  final result = await Process.run(executable, args);
  final String stdout = result.stdout;
  final String stderr = result.stderr;
  if (stdout.isNotEmpty) {
    print('stdout:');
    print(stdout);
  }
  if (stderr.isNotEmpty) {
    print('stderr:');
    print(stderr);
  }

  if (result.exitCode != 0) {
    throw 'Command failed with non-zero exit code (was ${result.exitCode})';
  }
}

withTempDir(Future fun(String dir)) async {
  final tempDir = Directory.systemTemp.createTempSync('bare-flag-test');
  try {
    await fun(tempDir.path);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
