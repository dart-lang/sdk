// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that when running in obfuscated mode, the AOT compiler
// generates a snapshot with obfuscated runtime information, but that static
// symbol tables in the unstripped snapshot and/or separate debugging
// information remains unobfuscated.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/src/dwarf_container.dart';
import 'package:native_stack_traces/src/macho.dart' as macho;
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
    final script = path.join(
      cwDir,
      'use_save_debugging_info_flag_program.dart',
    );
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
    await checkMachO(tempDir, scriptDill);
    await checkAssembly(tempDir, scriptDill);
  });
}

Future<List<String>?> retrieveDebugMap(
  SnapshotType snapshotType,
  String snapshotPath,
) async {
  // Don't check the debug map of assembled Mach-O snapshots.
  if (snapshotType != SnapshotType.machoDylib) return null;
  final dsymutil = llvmTool('dsymutil');
  if (dsymutil == null) {
    // Only return a null debug map if this part of the test should be
    // skipped on the current configuration.
    if (Platform.isWindows || Platform.isFuchsia) {
      // The identifier isn't provided on these platforms due to the lack
      // of a basename implementation, so no debug map can be extracted.
      return null;
    }
    if (isSimulator) {
      // clangBuildToolsDir uses Abi.current(), so it returns the buildtools
      // dir for the architecture being simulated, not the host.
      return null;
    }
    throw StateError('Expected dsymutil');
  }
  return await runOutput(dsymutil, ['--dump-debug-map', snapshotPath]);
}

final hasMinOSVersionOption = Platform.isMacOS || Platform.isIOS;
final expectedVersion = hasMinOSVersionOption ? macho.Version(1, 2, 3) : null;

Future<void> checkSnapshotType(
  String tempDir,
  String scriptDill,
  SnapshotType snapshotType,
) async {
  final commonOptions = <String>[];
  if (hasMinOSVersionOption && snapshotType == SnapshotType.machoDylib) {
    commonOptions.add('--macho-min-os-version=$expectedVersion');
  }
  // Run the AOT compiler without Dwarf stack trace, once without obfuscation,
  // once with obfuscation, and once with obfuscation and saving debugging
  // information.
  final scriptUnobfuscatedSnapshot = path.join(
    tempDir,
    'unobfuscated-$snapshotType.so',
  );
  await createSnapshot(
    scriptDill,
    snapshotType,
    scriptUnobfuscatedSnapshot,
    commonOptions,
  );
  final unobfuscatedCase = TestCase(
    snapshotType,
    scriptUnobfuscatedSnapshot,
    snapshotType.fromFile(scriptUnobfuscatedSnapshot)!,
    debugMap: await retrieveDebugMap(snapshotType, scriptUnobfuscatedSnapshot),
  );

  final scriptObfuscatedOnlySnapshot = path.join(
    tempDir,
    'obfuscated-only-$snapshotType.so',
  );
  await createSnapshot(scriptDill, snapshotType, scriptObfuscatedOnlySnapshot, [
    ...commonOptions,
    '--obfuscate',
  ]);
  final obfuscatedOnlyCase = TestCase(
    snapshotType,
    scriptObfuscatedOnlySnapshot,
    snapshotType.fromFile(scriptObfuscatedOnlySnapshot)!,
    debugMap: await retrieveDebugMap(
      snapshotType,
      scriptObfuscatedOnlySnapshot,
    ),
  );

  // Don't compare to separate debugging information for assembled snapshots
  // because the assembled code introduces a lot of local static symbols for
  // relocations and so the two won't contain similar amounts of static symbols.
  TestCase? obfuscatedCase;
  TestCase? strippedCase;
  if (snapshotType != SnapshotType.assembly) {
    final scriptObfuscatedSnapshot = path.join(
      tempDir,
      'obfuscated-$snapshotType.so',
    );
    final scriptDebuggingInfo = path.join(
      tempDir,
      'obfuscated-debug-$snapshotType.so',
    );
    await createSnapshot(scriptDill, snapshotType, scriptObfuscatedSnapshot, [
      ...commonOptions,
      '--obfuscate',
      '--save-debugging-info=$scriptDebuggingInfo',
    ]);
    obfuscatedCase = TestCase(
      snapshotType,
      scriptObfuscatedSnapshot,
      snapshotType.fromFile(scriptObfuscatedSnapshot)!,
      debuggingInfoContainer: snapshotType.fromFile(scriptDebuggingInfo)!,
      debugMap: await retrieveDebugMap(snapshotType, scriptObfuscatedSnapshot),
    );

    final scriptStrippedSnapshot = path.join(
      tempDir,
      'obfuscated-stripped-$snapshotType.so',
    );
    final scriptSeparateDebuggingInfo = path.join(
      tempDir,
      'obfuscated-separate-debug-$snapshotType.so',
    );
    await createSnapshot(scriptDill, snapshotType, scriptStrippedSnapshot, [
      ...commonOptions,
      '--strip',
      '--obfuscate',
      '--save-debugging-info=$scriptSeparateDebuggingInfo',
    ]);
    strippedCase = TestCase(
      snapshotType,
      scriptStrippedSnapshot,
      /*container=*/ null, // No static symbols in stripped snapshot.
      debuggingInfoContainer: snapshotType.fromFile(
        scriptSeparateDebuggingInfo,
      )!,
      // No N_OSO symbol in stripped Mach-O snapshots.
      debugMap: null,
    );
  }

  await checkCases(unobfuscatedCase, <TestCase>[
    obfuscatedOnlyCase,
    if (obfuscatedCase != null) obfuscatedCase,
  ], strippedCase);
}

Future<void> checkElf(String tempDir, String scriptDill) async {
  await checkSnapshotType(tempDir, scriptDill, SnapshotType.elf);
}

Future<void> checkMachO(String tempDir, String scriptDill) async {
  await checkSnapshotType(tempDir, scriptDill, SnapshotType.machoDylib);
}

Future<void> checkAssembly(String tempDir, String scriptDill) async {
  // Currently there are no appropriate buildtools on the simulator trybots as
  // normally they compile to ELF and don't need them for compiling assembly
  // snapshots.
  if (isSimulator || (!Platform.isLinux && !Platform.isMacOS)) return;
  await checkSnapshotType(tempDir, scriptDill, SnapshotType.assembly);
}

class TestCase {
  final SnapshotType type;
  final String snapshotPath;
  final DwarfContainer? container;
  final DwarfContainer? debuggingInfoContainer;
  final List<String>? debugMap;

  TestCase(
    this.type,
    this.snapshotPath,
    this.container, {
    this.debuggingInfoContainer,
    this.debugMap,
  });
}

Future<void> checkCases(
  TestCase unobfuscated,
  List<TestCase> unstrippedObfuscateds,
  TestCase? stripped,
) async {
  final obfuscateds = [
    ...unstrippedObfuscateds,
    if (stripped != null) stripped,
  ];
  checkStaticSymbolTables(unobfuscated, obfuscateds);
  await checkTraces(unobfuscated, obfuscateds);
  if (unobfuscated.debugMap != null) {
    checkDebugMaps(
      unobfuscated.debugMap!,
      unstrippedObfuscateds.map((c) => c.debugMap!).toList(),
    );
  }
  checkMachOSnapshots(unobfuscated, obfuscateds);
}

Future<void> checkTraces(
  TestCase unobfuscated,
  List<TestCase> obfuscateds,
) async {
  // Run the resulting scripts, saving the stack traces.
  final expectedTrace = await runError(dartPrecompiledRuntime, <String>[
    unobfuscated.snapshotPath,
  ]);

  print('');
  print("Original stack trace:");
  expectedTrace.forEach(print);

  final obfuscatedTraces = <List<String>>[];
  for (int i = 0; i < obfuscateds.length; i++) {
    obfuscatedTraces.add(
      await runError(dartPrecompiledRuntime, <String>[
        obfuscateds[i].snapshotPath,
      ]),
    );

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
    differs,
    'The obfuscated traces are identical to the unobfuscated trace',
  );
}

void checkStaticSymbolTables(TestCase expected, List<TestCase> cases) {
  final expectedSymbolNames = expected.container!.staticSymbols
      .map((o) => o.name)
      .toSet();

  if (expected.debuggingInfoContainer != null) {
    expectSimilarStaticSymbols(
      expectedSymbolNames,
      expected.debuggingInfoContainer!.staticSymbols.map((o) => o.name).toSet(),
    );
  }

  for (final got in cases) {
    if (got.container != null) {
      expectSimilarStaticSymbols(
        expectedSymbolNames,
        got.container!.staticSymbols.map((o) => o.name).toSet(),
      );
    }
    if (got.debuggingInfoContainer != null) {
      expectSimilarStaticSymbols(
        expectedSymbolNames,
        got.debuggingInfoContainer!.staticSymbols.map((o) => o.name).toSet(),
      );
    }
  }
}

const kMaxPercentAllowedDifferences = 0.01;

void expectSimilarStaticSymbols(Set<String> expected, Set<String> got) {
  final allowedDifferences = (expected.length * kMaxPercentAllowedDifferences)
      .floor();
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
    'more than $allowedDifferences.',
  );
}

final _tripleLineRegExp = RegExp(r'triple:\s+(.*)');
final _timestampLineRegExp = RegExp(r'timestamp:\s+(.*)');
// We only check that the number of symbols were the same.
final _symbolLineRegExp = RegExp(r'{ sym: ');

void checkDebugMaps(List<String> expected, List<List<String>> cases) {
  // The dump should look like the following YAML:
  // ---
  // triple:        '<arch>-<vendor>-<os>'
  // binary-path:   <filename>
  // objects:
  //   - filename:      <filename>
  //   - timestamp:     0
  //   - symbols:
  //     - { sym: <name>, ... }
  //     ...
  // ...
  //
  // The initial --- and ending ... are literal, as those are used to
  // separate multiple YAML documents in a single stream.
  //
  // For all test cases:
  // - The triple should be the same.
  // - The binary-path and filename lines should exist, though the filenames
  //   may be different.
  // - The timestamp should be 0.
  // - The number of symbols should be the same.
  Expect.isTrue(expected.length > 7);
  for (final c in cases) {
    Expect.equals(expected.length, c.length);
  }
  for (int i = 0; i < expected.length; i++) {
    final expectedLine = expected[i];
    final isSymbol = _symbolLineRegExp.hasMatch(expectedLine);
    final expectedTriple = _tripleLineRegExp.firstMatch(expectedLine)?.group(1);

    final expectedTimestampMatch = _timestampLineRegExp.firstMatch(
      expectedLine,
    );
    if (expectedTimestampMatch != null) {
      final expectedTimestamp = int.tryParse(expectedTimestampMatch.group(1)!);
      // The timestamp (value of the N_OSO symbol) in our snapshots is always 0.
      Expect.equals(0, expectedTimestamp);
    }

    // Lines that are allowed to have varying field values.
    final prefixOnlyLinePrefixes = ['binary-path: ', '  - filename: '];
    var expectedPrefixEnd = -1;
    if (prefixOnlyLinePrefixes.any((s) => expectedLine.startsWith(s))) {
      expectedPrefixEnd = expectedLine.indexOf(':');
    }

    for (final c in cases) {
      final gotLine = c[i];
      if (expectedTriple != null) {
        final gotTriple = _tripleLineRegExp.firstMatch(gotLine)?.group(1);
        Expect.equals(expectedTriple, gotTriple);
      } else if (isSymbol) {
        Expect.isTrue(_symbolLineRegExp.hasMatch(gotLine));
      } else if (expectedPrefixEnd > 0) {
        // If there's a unhandled field name, check that those match and don't
        // check the rest of the line (as, say, the filename will differ).
        Expect.stringEquals(
          expectedLine.substring(0, expectedLine.indexOf(':')),
          gotLine.substring(0, expectedLine.indexOf(':')),
        );
      } else {
        // Check line equality for anything not already covered.
        Expect.stringEquals(expectedLine, gotLine);
      }
    }
  }
}

// Checks for MachO snapshots (not separate debugging information).
void checkMachOSnapshots(TestCase unobfuscated, List<TestCase> obfuscateds) {
  checkMachOSnapshot(unobfuscated);
  obfuscateds.forEach(checkMachOSnapshot);
}

void checkMachOSnapshot(TestCase testCase) {
  // The checks below are only for snapshots, not for debugging information.
  final snapshot = testCase.container;
  if (snapshot is! macho.MachO) return;
  final buildVersion = snapshot
      .commandsWhereType<macho.BuildVersionCommand>()
      .singleOrNull;
  final expectedPlatform = Platform.isMacOS
      ? macho.Platform.PLATFORM_MACOS
      : Platform.isIOS
      ? macho.Platform.PLATFORM_IOS
      : null;
  Expect.equals(expectedPlatform, buildVersion?.platform);
  if (testCase.type == SnapshotType.machoDylib) {
    Expect.equals(expectedVersion, buildVersion?.minOS);
    Expect.equals(expectedVersion, buildVersion?.sdk);
    if (buildVersion != null) {
      Expect.isEmpty(buildVersion.toolVersions);
    }
  }
}
