// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is ensuring that the flag for --code-comments given at
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

  await withTempDir('code-comments-test', (String tempDir) async {
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

    // Run the AOT compiler with/without code comments.
    final scriptCommentedSnapshot = path.join(tempDir, 'comments.snapshot');
    final scriptUncommentedSnapshot =
        path.join(tempDir, 'no_comments.snapshot');
    await Future.wait(<Future>[
      run(genSnapshot, <String>[
        '--code-comments',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptCommentedSnapshot',
        scriptDill,
      ]),
      run(genSnapshot, <String>[
        '--no-code-comments',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptUncommentedSnapshot',
        scriptDill,
      ]),
    ]);

    // Run the AOT compiled script with code comments enabled.
    final commentsOut1 = path.join(tempDir, 'comments-out1.txt');
    final commentsOut2 = path.join(tempDir, 'comments-out2.txt');
    await Future.wait(<Future>[
      run(dartPrecompiledRuntime, <String>[
        '--code-comments',
        scriptCommentedSnapshot,
        scriptDill,
        commentsOut1,
      ]),
      run(dartPrecompiledRuntime, <String>[
        '--no-code-comments',
        scriptCommentedSnapshot,
        scriptDill,
        commentsOut2,
      ]),
    ]);

    // Run the AOT compiled script with code comments disabled.
    final uncommentedOut1 = path.join(tempDir, 'uncommented-out1.txt');
    final uncommentedOut2 = path.join(tempDir, 'uncommented-out2.txt');
    await Future.wait(<Future>[
      run(dartPrecompiledRuntime, <String>[
        '--code-comments',
        scriptUncommentedSnapshot,
        scriptDill,
        uncommentedOut1,
      ]),
      run(dartPrecompiledRuntime, <String>[
        '--no-code-comments',
        scriptUncommentedSnapshot,
        scriptDill,
        uncommentedOut2,
      ]),
    ]);

    // Ensure we got the same result each time.
    final output = await File(commentsOut1).readAsString();
    Expect.equals(output, await File(commentsOut2).readAsString());
    Expect.equals(output, await File(uncommentedOut1).readAsString());
    Expect.equals(output, await File(uncommentedOut2).readAsString());
  });
}
