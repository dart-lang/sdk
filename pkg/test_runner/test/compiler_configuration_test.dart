// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:test_runner/src/command.dart';
import 'package:test_runner/src/compiler_configuration.dart';

import 'utils.dart';

void main() {
  testCoffFiltersSaveDebuggingInfo();
  testElfKeepsSaveDebuggingInfo();
  testCoffRemovesObjectFile();
  testCoffLinkTargetRequiresX64();
}

void testCoffFiltersSaveDebuggingInfo() {
  final command = _precompilerCommandFor(
    [
      '--system=win',
      '--arch=x64',
      '--compiler=dartkp',
      '--runtime=dart_precompiled',
      '--gen-snapshot-format=coff',
    ],
    ['--dwarf-stack-traces', '--save-debugging-info=C:/tmp/debug.so'],
  );

  Expect.isTrue(command.arguments.contains('--dwarf-stack-traces'));
  Expect.isFalse(
    command.arguments.any((argument) {
      return argument.startsWith('--save-debugging-info');
    }),
  );
}

void testElfKeepsSaveDebuggingInfo() {
  final command = _precompilerCommandFor(
    [
      '--system=linux',
      '--arch=x64',
      '--compiler=dartkp',
      '--runtime=dart_precompiled',
      '--gen-snapshot-format=elf',
    ],
    ['--dwarf-stack-traces', '--save-debugging-info=/tmp/debug.so'],
  );

  Expect.isTrue(command.arguments.contains('--dwarf-stack-traces'));
  Expect.isTrue(
    command.arguments.contains('--save-debugging-info=/tmp/debug.so'),
  );
}

void testCoffRemovesObjectFile() {
  if (!Platform.isWindows) return;

  final artifact = _compilationArtifactFor([
    '--system=win',
    '--arch=x64',
    '--compiler=dartkp',
    '--runtime=dart_precompiled',
    '--gen-snapshot-format=coff',
  ], []);

  Expect.listEquals([
    'vm_compile_to_kernel',
    'precompiler',
    'remove_kernel_file',
    'link_coff',
    'remove_coff_object_file',
  ], artifact.commands.map((command) => command.displayName).toList());

  final removeObjectFileCommand = artifact.commands.last as ProcessCommand;
  Expect.equals('cmd.exe', removeObjectFileCommand.executable);
  Expect.listEquals([
    '/c',
    'del',
    r'\tmp\out\out.obj',
  ], removeObjectFileCommand.arguments);
}

void testCoffLinkTargetRequiresX64() {
  if (!Platform.isWindows) return;

  final command = _coffLinkCommandFor('x64');
  Expect.isTrue(command.arguments.contains('--target=x86_64-windows'));

  Expect.throws(() {
    runZoned(
      () => _coffLinkCommandFor('arm64'),
      zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
    );
  });
}

ProcessCommand _precompilerCommandFor(
  List<String> configurationOptions,
  List<String> vmOptions,
) {
  final configuration = makeConfiguration(configurationOptions, 'language');
  final testFile = createTestFile(
    source: '',
    path: 'coff_debug_info_test.dart',
  );
  final compilerConfiguration =
      configuration.compilerConfiguration as PrecompilerCompilerConfiguration;
  final arguments = compilerConfiguration.computeCompilerArguments(
    testFile,
    vmOptions,
    [testFile.path.toNativePath()],
  );
  return compilerConfiguration.computeGenSnapshotCommand(
        '/tmp/out',
        arguments,
        {},
      )
      as ProcessCommand;
}

CommandArtifact _compilationArtifactFor(
  List<String> configurationOptions,
  List<String> vmOptions,
) {
  final configuration = makeConfiguration(configurationOptions, 'language');
  final testFile = createTestFile(source: '', path: 'coff_artifact_test.dart');
  final compilerConfiguration =
      configuration.compilerConfiguration as PrecompilerCompilerConfiguration;
  final arguments = compilerConfiguration.computeCompilerArguments(
    testFile,
    vmOptions,
    [testFile.path.toNativePath()],
  );
  return compilerConfiguration.computeCompilationArtifact(
    '/tmp/out',
    arguments,
    {},
  );
}

ProcessCommand _coffLinkCommandFor(String architecture) {
  final configuration = makeConfiguration([
    '--system=win',
    '--arch=$architecture',
    '--compiler=dartkp',
    '--runtime=dart_precompiled',
    '--gen-snapshot-format=coff',
  ], 'language');
  final compilerConfiguration =
      configuration.compilerConfiguration as PrecompilerCompilerConfiguration;
  return compilerConfiguration.computeCoffLinkCommand('/tmp/out', {})
      as ProcessCommand;
}
