// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

final isAOTRuntime = path.basenameWithoutExtension(Platform.executable) ==
    'dart_precompiled_runtime';
final buildDir = path.dirname(Platform.executable);
final sdkDir = path.dirname(path.dirname(buildDir));
final platformDill = path.join(buildDir, 'vm_platform_strong.dill');
final genKernel = path.join(sdkDir, 'pkg', 'vm', 'tool',
    'gen_kernel' + (Platform.isWindows ? '.bat' : ''));
final _genSnapshotBase = 'gen_snapshot' + (Platform.isWindows ? '.exe' : '');
// Slight hack to work around issue that gen_snapshot for simarm_x64 is not
// in the same subdirectory as dart_precompiled_runtime (${MODE}SIMARM), but
// instead it's in ${MODE}SIMARM_X64.
final genSnapshot = File(path.join(buildDir, _genSnapshotBase)).existsSync()
    ? path.join(buildDir, _genSnapshotBase)
    : path.join(buildDir + '_X64', _genSnapshotBase);
final aotRuntime = path.join(
    buildDir, 'dart_precompiled_runtime' + (Platform.isWindows ? '.exe' : ''));

Future<ProcessResult> runHelper(String executable, List<String> args) async {
  print('Running $executable ${args.join(' ')}');

  final result = await Process.run(executable, args);
  if (result.stdout.isNotEmpty) {
    print('Subcommand stdout:');
    print(result.stdout);
  }
  if (result.stderr.isNotEmpty) {
    print('Subcommand stderr:');
    print(result.stderr);
  }

  return result;
}

Future<bool> testExecutable(String executable) async {
  try {
    final result = await runHelper(executable, <String>['--version']);
    return result.exitCode == 0;
  } on ProcessException catch (e) {
    print('Got process exception: $e');
    return false;
  }
}

Future<void> run(String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode != 0) {
    throw 'Command failed with unexpected exit code (was ${result.exitCode})';
  }
}

Future<Iterable<String>> runOutput(String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode != 0) {
    throw 'Command failed with unexpected exit code (was ${result.exitCode})';
  }
  Expect.isTrue(result.stdout.isNotEmpty);
  Expect.isTrue(result.stderr.isEmpty);

  return result.stdout.split(RegExp(r'[\r\n]'));
}

Future<Iterable<String>> runError(String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode == 0) {
    throw 'Command did not fail with non-zero exit code';
  }
  Expect.isTrue(result.stdout.isEmpty);
  Expect.isTrue(result.stderr.isNotEmpty);

  return result.stderr.split(RegExp(r'[\r\n]'));
}

Future<void> withTempDir(String name, Future<void> fun(String dir)) async {
  final tempDir = Directory.systemTemp.createTempSync(name);
  try {
    await fun(tempDir.path);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
