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

  final genKernelResult = runAndPrintOutput(
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
  print("Ran successfully.\n");

  final genAotResult = runAndPrintOutput(
    genSnapshot,
    [
      '--snapshot_kind=app-aot-elf',
      '--elf=$aotOutput',
      kernelOutput,
    ],
  );
  Expect.equals(genAotResult.exitCode, 0);
  print("Ran successfully.\n");

  final runAotResult = runAndPrintOutput(
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
  print('Got expected error result.');
}

ProcessResult runAndPrintOutput(String command, List<String> args) {
  print('Running $command ${args.join(' ')}...');
  final result = Process.runSync(command, args);
  if (result.stdout.isNotEmpty) {
    print("stdout: ");
    print(result.stdout);
  }
  if (result.stderr.isNotEmpty) {
    print("stderr: ");
    print(result.stderr);
  }
  return result;
}
