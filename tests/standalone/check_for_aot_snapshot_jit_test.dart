// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

main() {
  final buildDir = path.dirname(Platform.executable);
  final sdkDir = path.dirname(path.dirname(buildDir));
  final platformDill = path.join(buildDir, 'vm_platform_strong.dill');
  final genSnapshot = path.join(buildDir, 'gen_snapshot');

  final exePath = Platform.resolvedExecutable;
  final genSnapshotPath =
      Uri.parse(Platform.executable).resolve('gen_snapshot').path;
  final powTest = Platform.script.resolve('pow_test.dart').path;
  final d = Directory.systemTemp.createTempSync('aot_tmp');
  final kernelOutput = d.uri.resolve('pow_test.dill').path;
  final aotOutput = d.uri.resolve('pow_test.aot').path;

  final genKernelResult = Process.runSync(
    'pkg/vm/tool/gen_kernel',
    [
      '--aot',
      '--platform=$platformDill',
      '-o',
      kernelOutput,
      powTest,
    ],
  );
  Expect.equals(genKernelResult.exitCode, 0);

  final genAotResult = Process.runSync(
    genSnapshot,
    [
      '--snapshot_kind=app-aot-elf',
      '--elf=$aotOutput',
      kernelOutput,
    ],
  );
  Expect.equals(genAotResult.exitCode, 0);

  final runAotResult = Process.runSync(
    exePath,
    [
      'run',
      aotOutput,
    ],
  );
  Expect.equals(runAotResult.exitCode, 255);
  Expect.stringContainsInOrder(
    runAotResult.stderr,
    [
      "pow_test.aot is an AOT snapshot and should be run with 'dartaotruntime'",
    ],
  );
}
