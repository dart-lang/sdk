// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:async";
import "dart:io";
import "dart:convert";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!Platform.executable.endsWith("dart_precompiled_runtime")) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and gen_snapshot not available on the test device.
  }

  await withTempDir('emit_aot_size_info_flag', (String tempDir) async {
    final script = path.join(sdkDir, 'pkg/kernel/bin/dump.dart');
    final scriptDill = path.join(tempDir, 'kernel_dump.dill');
    final appHeapsnapshot = path.join(tempDir, 'app.heapsnapshot');
    final appSizesJson = path.join(tempDir, 'app-sizes.json');

    // Compile script to Kernel IR.
    await run('pkg/vm/tool/gen_kernel', <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    // Run the AOT compiler with the size information flags set.
    final elfFile = path.join(tempDir, 'aot.snapshot');
    await Future.wait(<Future>[
      run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-elf',
        '--print-instructions-sizes-to=$appSizesJson',
        '--write-v8-snapshot-profile-to=$appHeapsnapshot',
        '--elf=$elfFile',
        scriptDill,
      ]),
    ]);

    // Ensure we can actually run the code.
    await Future.wait(<Future>[
      run(dartPrecompiledRuntime, <String>[
        elfFile,
        scriptDill,
        path.join(tempDir, 'ignored.txt'),
      ]),
    ]);

    // Ensure we can read the files and they look legitimate.
    final appHeapsnapshotBytes = await readFile(appHeapsnapshot);
    final snapshotMap = json.decode(appHeapsnapshotBytes);
    Expect.isTrue(snapshotMap is Map);
    Expect.isTrue(snapshotMap.keys.contains('snapshot'));

    final appSizesJsonBytes = await readFile(appSizesJson);
    final sizeList = json.decode(appSizesJsonBytes);
    Expect.isTrue(sizeList is List);
    Expect.isTrue(sizeList[0] is Map);
    Expect.isTrue(sizeList[0].keys.toSet().containsAll(['n', 's']));
  });
}

Future<String> readFile(String file) {
  return new File(file).readAsString();
}
