// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:test_runner/src/command.dart';
import 'package:test_runner/src/compiler_configuration.dart';

import 'utils.dart';

void main() {
  testCoffFiltersSaveDebuggingInfo();
  testElfKeepsSaveDebuggingInfo();
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
