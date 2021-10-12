// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

final _execSuffix = Platform.isWindows ? '.exe' : '';
final _batchSuffix = Platform.isWindows ? '.bat' : '';

main() {
  final buildDir = path.dirname(Platform.executable);
  final sdkDir = path.dirname(path.dirname(buildDir));
  final platformDill = path.join(buildDir, 'vm_platform_strong.dill');
  final genKernel =
      path.join(sdkDir, 'pkg', 'vm', 'tool', 'gen_kernel$_batchSuffix');
  Expect.isTrue(File(genKernel).existsSync(),
      "Can't locate gen_kernel$_batchSuffix on this platform");
  Expect.isTrue(File(genKernel).existsSync(),
      "Can't locate gen_kernel$_batchSuffix on this platform");
  final genSnapshot = path.join(buildDir, 'gen_snapshot$_execSuffix');
  Expect.isTrue(File(genSnapshot).existsSync(),
      "Can't locate gen_snapshot$_execSuffix on this platform");

  final exePath = path.join(buildDir, 'dart$_execSuffix');
  Expect.isTrue(File(exePath).existsSync(),
      "Can't locate dart$_execSuffix on this platform");
  final powTest = path.join(sdkDir, 'tests', 'standalone_2', 'pow_test.dart');
  Expect.isTrue(File(powTest).existsSync(),
      "Can't locate dart$_execSuffix on this platform");
  final d = Directory.systemTemp.createTempSync('aot_tmp');
  final kernelOutput = File.fromUri(d.uri.resolve('pow_test.dill')).path;
  final aotOutput = File.fromUri(d.uri.resolve('pow_test.aot')).path;

  final genKernelResult = runAndPrintOutput(
    genKernel,
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

  final runAotDirectlyResult = runAndPrintOutput(
    exePath,
    [
      aotOutput,
    ],
  );
  Expect.equals(runAotDirectlyResult.exitCode, 255);
  Expect.contains(
      "pow_test.aot is an AOT snapshot and should be run with 'dartaotruntime'",
      runAotDirectlyResult.stderr);
  print('Got expected error result.');

  final runAotUsingCommandResult = runAndPrintOutput(
    exePath,
    [
      'run',
      aotOutput,
    ],
  );
  Expect.equals(runAotUsingCommandResult.exitCode, 255);
  Expect.containsOneOf(<String>[
    "pow_test.aot is an AOT snapshot and should be run with 'dartaotruntime'",
    // If dartdev itself failed, can happen on SIMARM as not enough is built
    // to run it.
    "Failed to start the Dart CLI isolate",
  ], runAotUsingCommandResult.stderr);
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
