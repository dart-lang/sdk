// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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
final genKernelDart = path.join('pkg', 'vm', 'bin', 'gen_kernel.dart');
final _genSnapshotBase = 'gen_snapshot' + (Platform.isWindows ? '.exe' : '');
final genSnapshot = () {
  final possiblePaths = [
    // No cross compilation.
    path.join(buildDir, _genSnapshotBase),
    // ${MODE}SIMARM_X64 for X64->SIMARM cross compilation.
    path.join('${buildDir}_X64', _genSnapshotBase),
    // ${MODE}XARM64/clang_x64 for X64->ARM64 cross compilation.
    path.join(buildDir, 'clang_x64', _genSnapshotBase),
  ];
  for (final path in possiblePaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  // We couldn't find an appropriate `gen_snapshot` executable, but it's
  // possible that the importing test doesn't actually use `genSnapshot`.
  // Instead of eagerly failing, just set `genSnapshot` to one of the
  // nonexistent paths. (In the `vm/dart` version, we use `late final`.)
  print('Could not find gen_snapshot for build directory $buildDir, '
      'using default path.');
  return possiblePaths.first;
}();
final dart = path.join(buildDir, 'dart' + (Platform.isWindows ? '.exe' : ''));
final dartPrecompiledRuntime = path.join(
    buildDir, 'dart_precompiled_runtime' + (Platform.isWindows ? '.exe' : ''));
final checkedInDartVM = path.join('tools', 'sdks', 'dart-sdk', 'bin',
    'dart' + (Platform.isWindows ? '.exe' : ''));

final isSimulator = path.basename(buildDir).contains('SIM');

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

Future<void> assembleSnapshot(String assemblyPath, String snapshotPath,
    {bool debug = false}) async {
  if (!Platform.isLinux && !Platform.isMacOS) {
    throw "Unsupported platform ${Platform.operatingSystem} for assembling";
  }

  final ccFlags = <String>[];
  final ldFlags = <String>[];
  String cc = 'gcc';
  String shared = '-shared';

  if (isSimulator) {
    final clangBuildTools = clangBuildToolsDir;
    if (clangBuildTools != null) {
      cc = path.join(clangBuildTools, 'clang');
    } else {
      throw 'Cannot assemble for ${path.basename(buildDir)} '
          'without //buildtools on ${Platform.operatingSystem}';
    }
  } else if (Platform.isMacOS) {
    cc = 'clang';
  }

  // TODO(49519): What do we need to change for SIMRISCV64?
  if (buildDir.endsWith('SIMARM')) {
    ccFlags.add('--target=armv7-linux-gnueabihf');
  } else if (buildDir.endsWith('SIMARM64')) {
    ccFlags.add('--target=aarch64-linux-gnu');
  } else if (Platform.isMacOS) {
    shared = '-dynamiclib';
    if (buildDir.endsWith('ARM64')) {
      // ld: dynamic main executables must link with libSystem.dylib for
      // architecture arm64
      ldFlags.add('-lSystem');
    }
    // Tell Mac linker to give up generating eh_frame from dwarf.
    ldFlags.add('-Wl,-no_compact_unwind');
  }

  if (buildDir.endsWith('X64') || buildDir.endsWith('SIMARM64')) {
    ccFlags.add('-m64');
  }
  if (debug) {
    ccFlags.add('-g');
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

  if (isSimulator || (Platform.isMacOS && forceElf)) {
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
  print('Subcommand terminated with exit code ${result.exitCode}.');
  if (result.stdout.isNotEmpty) {
    print('Subcommand stdout:');
    print(result.stdout);
  }
  if (result.exitCode != 0) {
    if (result.stderr.isNotEmpty) {
      print('Subcommand stderr:');
      print(result.stderr);
    }
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

  return LineSplitter.split(result.stdout).toList(growable: false);
}

Future<List<String>> runError(String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode == 0) {
    throw 'Command did not fail with non-zero exit code';
  }
  Expect.isTrue(result.stdout.isEmpty);
  Expect.isTrue(result.stderr.isNotEmpty);

  return LineSplitter.split(result.stderr).toList(growable: false);
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
