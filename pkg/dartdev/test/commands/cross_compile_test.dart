// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:code_assets/code_assets.dart';
import 'package:dartdev/src/commands/compile.dart'
    show
        CompileNativeCommand,
        crossCompileErrorExitCode,
        CompileSubcommandCommand;
import 'package:dartdev/src/target.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';
import 'compile_test.dart' show targetingHostOSMessage, usingTargetOSMessage;

void main() {
  ensureRunFromSdkBinDart();

  // Cross compilation is not available on 32-bit architectures.
  final hostArch = Target.current.architecture;
  final bool isRunningOn32Bit =
      hostArch == Architecture.ia32 ||
      hostArch == Architecture.arm ||
      hostArch == Architecture.riscv32;

  group(
    'cross compile -',
    defineCrossCompileTests,
    timeout: longTimeout,
    skip: isRunningOn32Bit,
  );
}

String unsupportedTargetMessage(Target target) =>
    'Unsupported target platform $target';
typedef TestFunction = Future<void> Function();

void defineCrossCompileTests() {
  final subcommands = [
    CompileNativeCommand.aotSnapshotCmdName,
    CompileNativeCommand.exeCmdName,
  ];
  final crossCompileTargets = CompileSubcommandCommand.supportedTargetPlatforms;
  String mainMessage(Target target) => 'I love ${target.os}';

  Future<(ProcessResult, String)> crossCompile(
    String subcommand,
    Target target,
  ) async {
    final p = project(
      mainSrc: 'void main() {print("${mainMessage(target)}");}',
    );
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final filename = subcommand == CompileNativeCommand.exeCmdName
        ? 'myexe'
        : subcommand == CompileNativeCommand.aotSnapshotCmdName
        ? 'out.so'
        : throw ArgumentError(
            'Unexpected subcommand $subcommand',
            'subcommand',
          );
    final outFile = path.canonicalize(path.join(p.dirPath, filename));
    final result = await p.run([
      'compile',
      subcommand,
      '-v',
      '--target-os',
      target.os.name,
      '--target-arch',
      target.architecture.name,
      '-o',
      outFile,
      inFile,
    ]);

    print('Subcommand terminated with exit code ${result.exitCode}.');
    if (result.stdout.isNotEmpty) {
      print('Subcommand stdout:');
      print(result.stdout);
    }
    if (result.stderr.isNotEmpty) {
      print('Subcommand stderr:');
      print(result.stderr);
    }

    return (result, outFile);
  }

  TestFunction crossCompileTest(String subcommand, Target target) => () async {
    expect(subcommand, isIn(subcommands));
    expect(target, isIn(crossCompileTargets));
    var (result, outFile) = await crossCompile(subcommand, target);

    expect(result.stdout, contains(usingTargetOSMessage(target.os)));
    expect(result.stderr, isNot(contains(unsupportedTargetMessage(target))));
    expect(result.exitCode, 0);
    expect(
      File(outFile).existsSync(),
      true,
      reason: 'File not found: $outFile',
    );

    if (target != Target.current) return;

    if (subcommand == CompileNativeCommand.exeCmdName) {
      result = Process.runSync(outFile, const []);
    } else {
      expect(subcommand, CompileNativeCommand.aotSnapshotCmdName);
      final Directory binDir = File(Platform.resolvedExecutable).parent;
      result = Process.runSync(path.join(binDir.path, 'dartaotruntime'), [
        outFile,
      ]);
    }

    expect(result.stdout, contains(mainMessage(target)));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  };

  TestFunction crossCompileFailureTest(String subcommand, Target target) =>
      () async {
        expect(subcommand, isIn(subcommands));
        expect(target, isNot(Target.current));
        expect(target, isNot(isIn(crossCompileTargets)));
        final (result, outFile) = await crossCompile(subcommand, target);

        expect(result.stdout, isNot(contains(targetingHostOSMessage)));
        expect(result.stdout, isNot(contains(usingTargetOSMessage(target.os))));
        expect(result.stderr, contains(unsupportedTargetMessage(target)));
        expect(result.exitCode, crossCompileErrorExitCode);
        expect(
          File(outFile).existsSync(),
          false,
          reason: 'File created despite failure: $outFile',
        );
      };

  for (final subcommand in subcommands) {
    for (final target in crossCompileTargets) {
      test(
        'Compile $subcommand can cross compile to $target',
        crossCompileTest(subcommand, target),
      );
    }
    var targetOS = Platform.isWindows ? OS.macOS : OS.windows;
    var targetArch = Architecture.arm64;
    var target = Target.fromArchitectureAndOS(targetArch, targetOS);
    test(
      'Compile $subcommand fails on invalid target OS',
      crossCompileFailureTest(subcommand, target),
    );

    targetOS = OS.linux;
    targetArch = Architecture.riscv32;
    target = Target.fromArchitectureAndOS(targetArch, targetOS);
    test(
      'Compile $subcommand fails on invalid target architecture',
      crossCompileFailureTest(subcommand, target),
    );
  }

  Future<(ProcessResult, String)> crossBuild(
    Target target,
  ) async {
    final p = project(
      mainSrc: 'void main() {print("${mainMessage(target)}");}',
    );
    final inFile = path.canonicalize(path.join(p.dirPath, p.relativeFilePath));
    final outDir = path.canonicalize(path.join(p.dirPath, 'mybuild'));
    final result = await p.run([
      'build',
      'cli',
      '-v',
      '--target-os',
      target.os.name,
      '--target-arch',
      target.architecture.name,
      '--target',
      inFile,
      '-o',
      outDir,
    ]);

    print('Build terminated with exit code ${result.exitCode}.');
    if (result.stdout.isNotEmpty) {
      print('Build stdout:');
      print(result.stdout);
    }
    if (result.stderr.isNotEmpty) {
      print('Build stderr:');
      print(result.stderr);
    }

    return (result, outDir);
  }

  TestFunction crossBuildTest(Target target) => () async {
    expect(target, isIn(crossCompileTargets));
    var (result, outDir) = await crossBuild(target);

    expect(result.stdout, contains(usingTargetOSMessage(target.os)));
    expect(result.stderr, isNot(contains(unsupportedTargetMessage(target))));
    expect(result.exitCode, 0);

    final exeName = target.os.executableFileName('main');
    final exeFile = File(path.join(outDir, 'bundle', 'bin', exeName));
    expect(
      exeFile.existsSync(),
      true,
      reason: 'Executable not found: ${exeFile.path}',
    );
    // Also when cross-compiling on a Linux host, whose `dartcliruntime` only
    // runs programs compiled for the host.
    expect(_ElfValidator.architecture(exeFile), target.architecture);

    if (target != Target.current) return;

    final runResult = Process.runSync(exeFile.path, const []);
    expect(runResult.stdout, contains(mainMessage(target)));
    expect(runResult.stderr, isEmpty);
    expect(runResult.exitCode, 0);
  };

  TestFunction crossBuildFailureTest(Target target) => () async {
    expect(target, isNot(Target.current));
    expect(target, isNot(isIn(crossCompileTargets)));
    final (result, outDir) = await crossBuild(target);

    expect(result.stdout, isNot(contains(targetingHostOSMessage)));
    expect(result.stdout, isNot(contains(usingTargetOSMessage(target.os))));
    expect(result.stderr, contains(unsupportedTargetMessage(target)));
    expect(result.exitCode, crossCompileErrorExitCode);
  };

  for (final target in crossCompileTargets) {
    test(
      'Build cli can cross compile to $target',
      crossBuildTest(target),
    );
  }
  final invalidOsTarget = Target.fromArchitectureAndOS(
    Architecture.arm64,
    Platform.isWindows ? OS.macOS : OS.windows,
  );
  test(
    'Build cli fails on invalid target OS',
    crossBuildFailureTest(invalidOsTarget),
  );

  final invalidArchTarget = Target.fromArchitectureAndOS(
    Architecture.riscv32,
    OS.linux,
  );
  test(
    'Build cli fails on invalid target architecture',
    crossBuildFailureTest(invalidArchTarget),
  );
}

/// Copied from
/// `dart-lang/native/pkgs/code_assets/lib/src/code_assets/elf_validator.dart`
/// to avoid importing `package:code_assets/src/...` internals.
abstract final class _ElfValidator {
  // The identification and machine values come from the System V ABI machine
  // table and the RISC-V ELF psABI:
  // https://gabi.xinuos.com/elf/a-emachine.html
  // https://github.com/riscv-non-isa/riscv-elf-psabi-doc/blob/master/riscv-elf.adoc
  static const _magic = [0x7f, 0x45, 0x4c, 0x46];
  static const _classOffset = 4;
  static const _class32 = 1;
  static const _class64 = 2;
  static const _dataOffset = 5;
  static const _dataLittleEndian = 1;
  static const _dataBigEndian = 2;
  static const _machineOffset = 18;
  static const _machineX86 = 3;
  static const _machineArm = 40;
  static const _machineX64 = 62;
  static const _machineArm64 = 183;
  static const _machineRiscV = 243;

  // The identification and the machine field occupy the first 20 bytes.
  static const _minLength = 20;

  static Architecture? architecture(File file) {
    final Uint8List head;
    final raf = file.openSync();
    try {
      head = raf.readSync(_minLength);
    } finally {
      raf.closeSync();
    }

    if (head.length < _minLength || !_hasMagic(head)) {
      return null;
    }
    final elfClass = head[_classOffset];
    final elfData = head[_dataOffset];
    if ((elfClass != _class32 && elfClass != _class64) ||
        (elfData != _dataLittleEndian && elfData != _dataBigEndian)) {
      return null;
    }

    final machine = ByteData.sublistView(head).getUint16(
      _machineOffset,
      elfData == _dataLittleEndian ? Endian.little : Endian.big,
    );
    return switch (machine) {
      _machineX86 => Architecture.ia32,
      _machineArm => Architecture.arm,
      _machineX64 => Architecture.x64,
      _machineArm64 => Architecture.arm64,
      _machineRiscV =>
        elfClass == _class32 ? Architecture.riscv32 : Architecture.riscv64,
      _ => null,
    };
  }

  static bool _hasMagic(Uint8List head) =>
      head[0] == _magic[0] &&
      head[1] == _magic[1] &&
      head[2] == _magic[2] &&
      head[3] == _magic[3];
}
