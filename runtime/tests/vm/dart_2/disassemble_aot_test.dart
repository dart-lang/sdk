// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests proper object recognition in disassembler.
import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

Future<void> main(List<String> args) async {
  if (Platform.isAndroid) {
    return; // SDK tree and gen_snapshot not available on the test device.
  }

  final buildDir = path.dirname(Platform.executable);
  final sdkDir = path.dirname(path.dirname(buildDir));
  final platformDill = path.join(buildDir, 'vm_platform_strong.dill');
  final genSnapshot = path.join(buildDir, 'gen_snapshot');

  await withTempDir('disassemble_aot', (String tempDir) async {
    final scriptDill = path.join(tempDir, 'out.dill');

    // Compile script to Kernel IR.
    await run('pkg/vm/tool/gen_kernel', <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      Platform.script.toString(),
    ]);

    // Run the AOT compiler with the disassemble flags set.
    final elfFile = path.join(tempDir, 'aot.snapshot');
    await Future.wait(<Future>[
      run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-elf',
        '--disassemble',
        '--always_generate_trampolines_for_testing',
        '--elf=$elfFile',
        scriptDill,
      ]),
    ]);
  });
}
