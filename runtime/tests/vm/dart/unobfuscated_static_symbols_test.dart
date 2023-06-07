// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that when running in obfuscated mode, the AOT compiler
// generates a snapshot with obfuscated runtime information, but that static
// symbol tables in the unstripped snapshot and/or separate debugging
// information remains unobfuscated.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:io";
import "dart:math";
import "dart:typed_data";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:native_stack_traces/src/dwarf_container.dart';
import 'package:native_stack_traces/src/macho.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

Future<void> main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
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

  await withTempDir('unobfuscated-static-symbols-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script =
        path.join(cwDir, 'use_save_debugging_info_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    await checkElf(tempDir, scriptDill);
    await checkAssembly(tempDir, scriptDill);
  });
}

const commonGenSnapshotArgs = <String>[
  // Make sure that the runs are deterministic so we can depend on the same
  // snapshot being generated each time.
  '--deterministic',
];

Future<void> checkElf(String tempDir, String scriptDill) async {
  // Run the AOT compiler without Dwarf stack trace, once without obfuscation,
  // once with obfuscation, and once with obfuscation and saving debugging
  // information.
  final scriptUnobfuscatedSnapshot = path.join(tempDir, 'unobfuscated-elf.so');
  await run(genSnapshot, <String>[
    ...commonGenSnapshotArgs,
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptUnobfuscatedSnapshot',
    scriptDill,
  ]);
  final unobfuscatedCase = TestCase(
      scriptUnobfuscatedSnapshot, Elf.fromFile(scriptUnobfuscatedSnapshot)!);

  final scriptObfuscatedOnlySnapshot =
      path.join(tempDir, 'obfuscated-only-elf.so');
  await run(genSnapshot, <String>[
    ...commonGenSnapshotArgs,
    '--obfuscate',
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptObfuscatedOnlySnapshot',
    scriptDill,
  ]);
  final obfuscatedOnlyCase = TestCase(scriptObfuscatedOnlySnapshot,
      Elf.fromFile(scriptObfuscatedOnlySnapshot)!);

  final scriptObfuscatedSnapshot = path.join(tempDir, 'obfuscated-elf.so');
  final scriptDebuggingInfo = path.join(tempDir, 'obfuscated-debug-elf.so');
  await run(genSnapshot, <String>[
    ...commonGenSnapshotArgs,
    '--obfuscate',
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptObfuscatedSnapshot',
    '--save-debugging-info=$scriptDebuggingInfo',
    scriptDill,
  ]);
  final obfuscatedCase = TestCase(
      scriptObfuscatedSnapshot,
      Elf.fromFile(scriptObfuscatedSnapshot)!,
      Elf.fromFile(scriptDebuggingInfo)!);

  await checkCases(unobfuscatedCase, <TestCase>[
    obfuscatedOnlyCase,
    obfuscatedCase,
  ]);
}

Future<void> checkAssembly(String tempDir, String scriptDill) async {
  // Currently there are no appropriate buildtools on the simulator trybots as
  // normally they compile to ELF and don't need them for compiling assembly
  // snapshots.
  if (isSimulator || (!Platform.isLinux && !Platform.isMacOS)) return;

  // Run the AOT compiler without Dwarf stack trace, once without obfuscation,
  // once with obfuscation, and once with obfuscation and saving debugging
  // information.
  final scriptUnobfuscatedAssembly =
      path.join(tempDir, 'unobfuscated-assembly.S');
  final scriptUnobfuscatedSnapshot =
      path.join(tempDir, 'unobfuscated-assembly.so');
  await run(genSnapshot, <String>[
    ...commonGenSnapshotArgs,
    '--snapshot-kind=app-aot-assembly',
    '--assembly=$scriptUnobfuscatedAssembly',
    scriptDill,
  ]);
  await assembleSnapshot(
      scriptUnobfuscatedAssembly, scriptUnobfuscatedSnapshot);
  final unobfuscatedCase = TestCase(
      scriptUnobfuscatedSnapshot,
      Platform.isMacOS
          ? MachO.fromFile(scriptUnobfuscatedSnapshot)!
          : Elf.fromFile(scriptUnobfuscatedSnapshot)!);

  final scriptObfuscatedOnlyAssembly =
      path.join(tempDir, 'obfuscated-only-assembly.S');
  final scriptObfuscatedOnlySnapshot =
      path.join(tempDir, 'obfuscated-only-assembly.so');
  await run(genSnapshot, <String>[
    ...commonGenSnapshotArgs,
    '--obfuscate',
    '--snapshot-kind=app-aot-assembly',
    '--assembly=$scriptObfuscatedOnlyAssembly',
    scriptDill,
  ]);
  await assembleSnapshot(
      scriptObfuscatedOnlyAssembly, scriptObfuscatedOnlySnapshot);
  final obfuscatedOnlyCase = TestCase(
      scriptObfuscatedOnlySnapshot,
      Platform.isMacOS
          ? MachO.fromFile(scriptObfuscatedOnlySnapshot)!
          : Elf.fromFile(scriptObfuscatedOnlySnapshot)!);

  await checkCases(unobfuscatedCase, <TestCase>[
    obfuscatedOnlyCase,
  ]);
}

class TestCase {
  final String snapshotPath;
  final DwarfContainer container;
  final DwarfContainer? debuggingInfoContainer;

  TestCase(this.snapshotPath, this.container, [this.debuggingInfoContainer]);
}

Future<void> checkCases(
    TestCase unobfuscated, List<TestCase> obfuscateds) async {
  checkStaticSymbolTables(unobfuscated, obfuscateds);
  await checkTraces(unobfuscated, obfuscateds);
}

Future<void> checkTraces(
    TestCase unobfuscated, List<TestCase> obfuscateds) async {
  // Run the resulting scripts, saving the stack traces.
  final expectedTrace = await runError(dartPrecompiledRuntime, <String>[
    unobfuscated.snapshotPath,
  ]);

  print('');
  print("Original stack trace:");
  expectedTrace.forEach(print);

  final obfuscatedTraces = <List<String>>[];
  for (int i = 0; i < obfuscateds.length; i++) {
    obfuscatedTraces.add(await runError(dartPrecompiledRuntime, <String>[
      obfuscateds[i].snapshotPath,
    ]));

    print('');
    print("Obfuscated stack trace ${i + 1}:");
    obfuscatedTraces[i].forEach(print);

    if (i != 0) {
      // Compare with the previous trace, as all obfuscated traces should be
      // the same as the obfuscation is deterministic.
      Expect.deepEquals(obfuscatedTraces[i - 1], obfuscatedTraces[i]);
    }
  }

  // The unobfuscated trace should differ from all obfuscated traces.
  Expect.isNotEmpty(obfuscateds);
  final gotTrace = obfuscatedTraces[0];
  Expect.equals(expectedTrace.length, gotTrace.length);
  bool differs = false;
  for (int i = 0; i < expectedTrace.length; i++) {
    if (expectedTrace[i] != gotTrace[i]) {
      differs = true;
    }
  }
  Expect.isTrue(
      differs, 'The obfuscated traces are identical to the unobfuscated trace');
}

void checkStaticSymbolTables(TestCase expected, List<TestCase> cases) {
  final expectedSymbolNames =
      expected.container.staticSymbols.map((o) => o.name).toSet();

  if (expected.debuggingInfoContainer != null) {
    expectSimilarStaticSymbols(
        expectedSymbolNames,
        expected.debuggingInfoContainer!.staticSymbols
            .map((o) => o.name)
            .toSet());
  }

  for (final got in cases) {
    expectSimilarStaticSymbols(expectedSymbolNames,
        got.container.staticSymbols.map((o) => o.name).toSet());
    if (got.debuggingInfoContainer != null) {
      expectSimilarStaticSymbols(expectedSymbolNames,
          got.debuggingInfoContainer!.staticSymbols.map((o) => o.name).toSet());
    }
  }
}

const kMaxPercentAllowedDifferences = 0.01;

void expectSimilarStaticSymbols(Set<String> expected, Set<String> got) {
  final allowedDifferences =
      (expected.length * kMaxPercentAllowedDifferences).floor();
  // There are cases where we cannot assume that we have the exact same symbols
  // in both snapshots (e.g., because we're using an assembler that adds
  // symbols with randomly generated names). Instead, we compare them manually,
  // counting the number of symbols not found in one or the other, and allow
  // a small number of differences. (We generate _a lot_ of static symbols, so
  // if the vast majority match we can assume that no obfuscation happened.)
  final onlyExpected = <String>[];
  for (final name in expected) {
    if (!got.contains(name)) {
      onlyExpected.add(name);
    }
  }
  print('');
  print('Symbols found only in expected:');
  onlyExpected.forEach(print);

  final onlyGot = <String>[];
  for (final name in got) {
    if (!expected.contains(name)) {
      onlyGot.add(name);
    }
  }
  print('');
  print('Symbols found only in got:');
  onlyGot.forEach(print);

  final differences = onlyExpected.length + onlyGot.length;
  Expect.isTrue(
      differences <= allowedDifferences,
      'Got $differences different symbols, which is '
      'more than $allowedDifferences.');
}
