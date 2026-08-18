// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that symbols in MH_OBJECT outputs from gen_snapshot are sorted by name.

import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

final nm = llvmTool('llvm-nm', verbose: true);

void main() async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
  }

  if (isSimulator) {
    // Output of Mach-O relocatable objects isn't supported for most
    // simulated architectures, so don't run the test.
    return;
  }

  if (nm == null) {
    return;
  }

  // These are the tools we need to be available to run on a given platform:
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }
  if (!await testExecutable(dartPrecompiledRuntime)) {
    throw "Cannot run test as $dartPrecompiledRuntime not available";
  }
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }

  await withTempDir('regress-64051', (String tempDir) async {
    // We have to use the program in its original location so it can use
    // the dart:_internal library (as opposed to adding it as an OtherResources
    // option to the test).
    final scriptPath = path.join(
      sdkDir,
      'runtime',
      'tests',
      'vm',
      'dart',
      'use_dwarf_stack_traces_flag_program.dart',
    );

    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      scriptPath,
    ]);

    final snapshotPath = path.join(tempDir, 'regress_64051.so');
    final objectPath = path.join(tempDir, 'regress_64051.o');
    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-macho-dylib',
      '--macho=$snapshotPath',
      '--macho-object=$objectPath',
      scriptDill,
    ]);

    // Currently the text section is added before the data section, and the
    // symbol for the text section is lexicographically larger than the data
    // section's, so address order != sorted order. The MH_DYLIB output
    // (--macho) uses address order, whereas the MH_OBJECT output
    // (--macho-object) _should_ use sorted order.
    final sortedDylibOutput = await printSymbols(snapshotPath, sorted: true);
    final sortedObjectOutput = await printSymbols(objectPath, sorted: true);
    Expect.listEquals(sortedDylibOutput, sortedObjectOutput);

    final unsortedDylibOutput = await printSymbols(snapshotPath, sorted: false);
    final unsortedObjectOutput = await printSymbols(objectPath, sorted: false);
    Expect.listEquals(sortedObjectOutput, unsortedObjectOutput);

    var different = false;
    Expect.equals(sortedDylibOutput.length, unsortedDylibOutput.length);
    for (int i = 0; i < sortedDylibOutput.length; i++) {
      if (sortedDylibOutput[i] != unsortedDylibOutput[i]) {
        different = true;
      }
    }
    Expect.isTrue(different, 'sorted and unsorted dylib symbols are the same');
  });
}

// nm's output is <hex address> <symbol type> <name>.
final _symbolNameRegExp = RegExp(r'^[0-9a-fA-F]+ . (.*)');

Future<List<String>> printSymbols(String path, {required bool sorted}) async {
  final result = await runHelper(nm!, [if (!sorted) '-p', '-g', path]);

  if (result.exitCode != 0) {
    throw 'Command failed with non-zero exit code ${result.exitCode}';
  }
  if (result.stdout.isEmpty) {
    throw 'Command did not print output';
  }

  return LineSplitter.split(result.stdout).toList().map((l) {
    final match = _symbolNameRegExp.firstMatch(l);
    Expect.isNotNull(match);
    return match!.group(1)!;
  }).toList();
}
