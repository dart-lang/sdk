// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:ffi';

import 'package:expect/config.dart';
import 'package:expect/expect.dart';
import 'package:native_stack_traces/src/elf.dart' show Elf;
import 'package:native_stack_traces/src/dwarf_container.dart'
    show DwarfContainer;
import 'package:native_stack_traces/src/macho.dart' show MachO;
import 'package:path/path.dart' as path;

final isAOTRuntime = isVmAotConfiguration;
final buildDir = path.dirname(Platform.executable);
final sdkDir = path.dirname(path.dirname(buildDir));
late final platformDill = () {
  final possiblePaths = [
    // No cross compilation.
    path.join(buildDir, 'vm_platform.dill'),
    // ${MODE}SIMARM_X64 for X64->SIMARM cross compilation.
    path.join('${buildDir}_X64', 'vm_platform.dill'),
  ];
  for (final path in possiblePaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  throw 'Could not find vm_platform.dill for build directory $buildDir';
}();
final genKernel = path.join(
  sdkDir,
  'pkg',
  'vm',
  'tool',
  'gen_kernel' + (Platform.isWindows ? '.bat' : ''),
);
final genKernelDart = path.join('pkg', 'vm', 'bin', 'gen_kernel.dart');
final exeSuffix = Platform.isWindows ? '.exe' : '';
final _genSnapshotBase = 'gen_snapshot$exeSuffix';
// Lazily initialize `genSnapshot` so that tests that don't use it on platforms
// that don't have a `gen_snapshot` don't fail.
late final genSnapshot = () {
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
  throw 'Could not find gen_snapshot for build directory $buildDir';
}();
final dart = path.join(buildDir, 'dartvm$exeSuffix');
final dartPrecompiledRuntime = path.join(buildDir, 'dartaotruntime$exeSuffix');
final checkedInDartVM = path.join(
  'tools',
  'sdks',
  'dart-sdk',
  'bin',
  'dart$exeSuffix',
);
String? llvmTool(String name, {bool verbose = false}) {
  final clangBuildTools = clangBuildToolsDir;
  if (clangBuildTools != null) {
    final toolPath = path.join(clangBuildTools, '$name$exeSuffix');
    if (File(toolPath).existsSync()) {
      return toolPath;
    }
    if (verbose) {
      print('Could not find $name binary at $toolPath');
    }
    return null;
  }
  if (verbose) {
    print('Could not find $name binary');
  }
  return null;
}

final isSimulator = path.basename(buildDir).contains('SIM');

String? get clangBuildToolsDir {
  for (var archDir in [
    'mac-arm64',
    'mac-x64',
    'win-arm64',
    'win-x64',
    'linux-arm64',
    'linux-x64',
  ]) {
    var clangDir = path.join(sdkDir, 'buildtools', archDir, 'clang', 'bin');
    if (Directory(clangDir).existsSync()) return clangDir;
  }
  return null;
}

Future<void> assembleSnapshot(
  String assemblyPath,
  String snapshotPath, {
  bool debug = false,
}) async {
  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
    throw "Unsupported platform ${Platform.operatingSystem} for assembling";
  }

  final ccFlags = <String>[];
  final ldFlags = <String>[];
  String cc = 'gcc';
  String shared = '-shared';

  final clangBuildTools = clangBuildToolsDir;
  if (clangBuildTools != null) {
    cc = path.join(clangBuildTools, 'clang$exeSuffix');
  } else {
    throw 'Cannot assemble for ${path.basename(buildDir)} '
        'without //buildtools on ${Platform.operatingSystem}';
  }

  if (Platform.isMacOS) {
    shared = '-dynamiclib';
    if (buildDir.endsWith('ARM64')) {
      ccFlags.add('--target=arm64-apple-darwin');
    } else {
      ccFlags.add('--target=x86_64-apple-darwin');
    }
  } else if (Platform.isLinux) {
    if (buildDir.endsWith('ARM') || buildDir.endsWith('SIMARM_X64')) {
      ccFlags.add('--target=armv7-linux-gnueabihf');
    } else if (buildDir.endsWith('ARM64')) {
      ccFlags.add('--target=aarch64-linux-gnu');
    } else if (buildDir.endsWith('X64')) {
      ccFlags.add('--target=x86_64-linux-gnu');
    } else if (buildDir.endsWith('RISCV64')) {
      ccFlags.add('--target=riscv64-linux-gnu');
    }
  }

  if (debug) {
    ccFlags.add('-g');
  }

  await run(cc, <String>[
    ...ccFlags,
    ...ldFlags,
    '-nostdlib',
    shared,
    '-o',
    snapshotPath,
    assemblyPath,
  ]);
}

Future<void> stripSnapshot(
  String snapshotPath,
  String strippedPath, {
  bool forceElf = false,
}) async {
  if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
    throw "Unsupported platform ${Platform.operatingSystem} for stripping";
  }

  var strip = 'strip';

  final clangBuildTools = clangBuildToolsDir;
  if (clangBuildTools != null) {
    strip = path.join(clangBuildTools, 'llvm-strip$exeSuffix');
  } else {
    throw 'Cannot strip ELF files for ${path.basename(buildDir)} '
        'without //buildtools on ${Platform.operatingSystem}';
  }

  await run(strip, <String>['-o', strippedPath, snapshotPath]);
}

Future<ProcessResult> runHelper(
  String executable,
  List<String> args, {
  bool printStdout = true,
  bool printStderr = true,
}) async {
  print('Running $executable ${args.join(' ')}');

  final result = await Process.run(executable, args);
  print('Subcommand terminated with exit code ${result.exitCode}.');
  if (printStdout && result.stdout.isNotEmpty) {
    print('Subcommand stdout:');
    print(result.stdout);
  }
  if (printStderr && result.stderr.isNotEmpty) {
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

Future<void> runSilent(String executable, List<String> args) async {
  final result = await runHelper(
    executable,
    args,
    printStdout: false,
    printStderr: false,
  );

  if (result.exitCode != 0) {
    throw 'Command failed with unexpected exit code (was ${result.exitCode})';
  }
}

Future<List<String>> runOutput(
  String executable,
  List<String> args, {
  bool ignoreStdErr = false,
  bool printStdout = true,
  bool printStderr = true,
}) async {
  final result = await runHelper(
    executable,
    args,
    printStdout: printStdout,
    printStderr: printStderr,
  );

  if (result.exitCode != 0) {
    throw 'Command failed with unexpected exit code (was ${result.exitCode})';
  }
  Expect.isTrue(result.stdout.isNotEmpty);
  if (!ignoreStdErr) {
    Expect.isTrue(result.stderr.isEmpty);
  }

  return LineSplitter.split(result.stdout).toList(growable: false);
}

Future<List<String>> runError(
  String executable,
  List<String> args, {
  bool printStdout = true,
  bool printStderr = true,
}) async {
  final result = await runHelper(
    executable,
    args,
    printStdout: printStdout,
    printStderr: printStderr,
  );

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
        Platform.environment[keepTempKey]!.isEmpty) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

enum SnapshotType {
  elf,
  machoDylib,
  assembly;

  String get kindString {
    switch (this) {
      case elf:
        return 'app-aot-elf';
      case machoDylib:
        return 'app-aot-macho-dylib';
      case assembly:
        return 'app-aot-assembly';
    }
  }

  String get fileArgumentName {
    switch (this) {
      case elf:
        return 'elf';
      case machoDylib:
        return 'macho';
      case assembly:
        return 'assembly';
    }
  }

  DwarfContainer? fromFile(String filename) {
    switch (this) {
      case elf:
        return Elf.fromFile(filename);
      case machoDylib:
        return MachO.fromFile(filename);
      case assembly:
        return Elf.fromFile(filename) ?? MachO.fromFile(filename);
    }
  }

  @override
  String toString() => name;
}

const _commonGenSnapshotArgs = <String>[
  // Make sure that the runs are deterministic so we can depend on the same
  // snapshot being generated each time.
  '--deterministic',
];

Future<void> createSnapshot(
  String scriptDill,
  SnapshotType snapshotType,
  String finalPath, [
  List<String> extraArgs = const [],
]) async {
  String output = finalPath;
  if (snapshotType == SnapshotType.assembly) {
    output = path.withoutExtension(finalPath) + '.S';
  }
  await run(genSnapshot, <String>[
    ..._commonGenSnapshotArgs,
    ...extraArgs,
    '--snapshot-kind=${snapshotType.kindString}',
    '--${snapshotType.fileArgumentName}=$output',
    scriptDill,
  ]);
  if (snapshotType == SnapshotType.assembly) {
    await assembleSnapshot(output, finalPath);
  }
}
