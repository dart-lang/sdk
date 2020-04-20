// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:convert";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

main(List<String> args) async {
  if (!Platform.executable.endsWith("dart_precompiled_runtime")) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and gen_snapshot not available on the test device.
  }

  final buildDir = path.dirname(Platform.executable);
  final sdkDir = path.dirname(path.dirname(buildDir));
  final platformDill = path.join(buildDir, 'vm_platform_strong.dill');
  final genSnapshot = path.join(buildDir, 'gen_snapshot');
  final aotRuntime = path.join(buildDir, 'dart_precompiled_runtime');

  await withTempDir((String tempDir) async {
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
      run(aotRuntime, <String>[
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

Future withTempDir(Future fun(String dir)) async {
  final tempDir =
      Directory.systemTemp.createTempSync('aot-size-info-flags-test');
  try {
    await fun(tempDir.path);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
