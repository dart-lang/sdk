// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:dartdev/src/commands/compile.dart'
    show CompileNativeCommand, crossCompileErrorExitCode;
import 'package:hooks_runner/hooks_runner.dart';
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
  final crossCompileTargets = CompileNativeCommand.supportedTargetPlatforms;
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
}
