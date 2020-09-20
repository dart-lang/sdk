// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
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

String get clangBuildToolsDir {
  String archDir;
  if (Platform.isLinux) {
    archDir = 'linux-x64';
  } else if (Platform.isMacOS) {
    archDir = 'mac-x64';
  } else {
    return null;
  }
  var clangDir = path.join(sdkDir, 'buildtools', archDir, 'clang', 'bin');
  return Directory(clangDir).existsSync() ? clangDir : null;
}

Future<void> assembleSnapshot(String assemblyPath, String snapshotPath) async {
  if (!Platform.isLinux && !Platform.isMacOS) {
    throw "Unsupported platform ${Platform.operatingSystem} for assembling";
  }

  final ccFlags = <String>[];
  final ldFlags = <String>[];
  String cc = 'gcc';
  String shared = '-shared';

  if (Platform.isMacOS) {
    cc = 'clang';
  } else if (buildDir.endsWith('SIMARM') || buildDir.endsWith('SIMARM64')) {
    if (clangBuildToolsDir != null) {
      cc = path.join(clangBuildToolsDir, 'clang');
    } else {
      throw 'Cannot assemble for ${path.basename(buildDir)} '
          'without //buildtools on ${Platform.operatingSystem}';
    }
  }

  if (Platform.isMacOS) {
    shared = '-dynamiclib';
    // Tell Mac linker to give up generating eh_frame from dwarf.
    ldFlags.add('-Wl,-no_compact_unwind');
  } else if (buildDir.endsWith('SIMARM')) {
    ccFlags.add('--target=armv7-linux-gnueabihf');
  } else if (buildDir.endsWith('SIMARM64')) {
    ccFlags.add('--target=aarch64-linux-gnu');
  }

  if (buildDir.endsWith('X64') || buildDir.endsWith('SIMARM64')) {
    ccFlags.add('-m64');
  }

  await run(cc, <String>[
    ...ccFlags,
    ...ldFlags,
    shared,
    '-nostdlib',
    '-o',
    snapshotPath,
    assemblyPath,
  ]);
}

Future<void> stripSnapshot(String snapshotPath, String strippedPath,
    {bool forceElf = false}) async {
  if (!Platform.isLinux && !Platform.isMacOS) {
    throw "Unsupported platform ${Platform.operatingSystem} for stripping";
  }

  var strip = 'strip';

  if ((Platform.isLinux &&
          (buildDir.endsWith('SIMARM') || buildDir.endsWith('SIMARM64'))) ||
      (Platform.isMacOS && forceElf)) {
    if (clangBuildToolsDir != null) {
      strip = path.join(clangBuildToolsDir, 'llvm-strip');
    } else {
      throw 'Cannot strip ELF files for ${path.basename(buildDir)} '
          'without //buildtools on ${Platform.operatingSystem}';
    }
  }

  await run(strip, <String>[
    '-o',
    strippedPath,
    snapshotPath,
  ]);
}

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

Future<List<String>> runOutput(String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode != 0) {
    throw 'Command failed with unexpected exit code (was ${result.exitCode})';
  }
  Expect.isTrue(result.stdout.isNotEmpty);
  Expect.isTrue(result.stderr.isEmpty);

  return await Stream.value(result.stdout as String)
      .transform(const LineSplitter())
      .toList();
}

Future<List<String>> runError(String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode == 0) {
    throw 'Command did not fail with non-zero exit code';
  }
  Expect.isTrue(result.stdout.isEmpty);
  Expect.isTrue(result.stderr.isNotEmpty);

  return await Stream.value(result.stderr as String)
      .transform(const LineSplitter())
      .toList();
}

const keepTempKey = 'KEEP_TEMPORARY_DIRECTORIES';

Future<void> withTempDir(String name, Future<void> fun(String dir)) async {
  final tempDir = Directory.systemTemp.createTempSync(name);
  try {
    await fun(tempDir.path);
  } finally {
    if (!Platform.environment.containsKey(keepTempKey) ||
        Platform.environment[keepTempKey].isEmpty) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
