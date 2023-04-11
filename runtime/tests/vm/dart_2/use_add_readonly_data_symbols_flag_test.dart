// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test checks that --add-readonly-data-symbols outputs static symbols
// for read-only data objects.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
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

  await withTempDir('readonly-symbols-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script =
        path.join(cwDir, 'use_save_debugging_info_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--no-sound-null-safety',
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    final scriptSnapshot = path.join(tempDir, 'dwarf.so');
    final scriptDebuggingInfo = path.join(tempDir, 'debug_info.so');
    await run(genSnapshot, <String>[
      '--no-sound-null-safety',
      '--add-readonly-data-symbols',
      '--dwarf-stack-traces-mode',
      '--save-debugging-info=$scriptDebuggingInfo',
      '--snapshot-kind=app-aot-elf',
      '--elf=$scriptSnapshot',
      scriptDill,
    ]);

    final snapshotElf = Elf.fromFile(scriptSnapshot);
    Expect.isNotNull(snapshotElf);
    final debugInfoElf = Elf.fromFile(scriptDebuggingInfo);
    Expect.isNotNull(debugInfoElf);

    checkElf(snapshotElf, debugInfoElf, isAssembled: false);

    if ((Platform.isLinux || Platform.isMacOS) && !isSimulator) {
      final scriptAssembly = path.join(tempDir, 'snapshot.S');
      final scriptAssemblySnapshot = path.join(tempDir, 'assembly.so');
      final scriptAssemblyDebuggingInfo =
          path.join(tempDir, 'assembly_debug.so');

      await run(genSnapshot, <String>[
        '--add-readonly-data-symbols',
        '--dwarf-stack-traces-mode',
        '--save-debugging-info=$scriptAssemblyDebuggingInfo',
        '--snapshot-kind=app-aot-assembly',
        '--assembly=$scriptAssembly',
        scriptDill,
      ]);

      await assembleSnapshot(scriptAssembly, scriptAssemblySnapshot,
          debug: true);

      // This one may be null if on MacOS.
      final assembledElf = Elf.fromFile(scriptAssemblySnapshot);
      if (Platform.isLinux) {
        Expect.isNotNull(assembledElf);
      }
      final assembledDebugElf = Elf.fromFile(scriptAssemblyDebuggingInfo);
      Expect.isNotNull(assembledDebugElf);

      checkElf(assembledElf, assembledDebugElf, isAssembled: true);
    }
  });
}

final _uniqueSuffixRegexp = RegExp(r' \(#\d+\)');

void checkVMSymbolsAreValid(Iterable<Symbol> symbols,
    {String source, bool isAssembled}) {
  print("Checking VM symbols from $source:");
  for (final symbol in symbols) {
    print(symbol);
    // All VM-created symbols should have sizes.
    Expect.notEquals(0, symbol.size);
    if (symbol.bind != SymbolBinding.STB_GLOBAL &&
        symbol.bind != SymbolBinding.STB_LOCAL) {
      Expect.fail('Unexpected symbol binding ${symbol.bind}');
    }
    if (symbol.bind == SymbolBinding.STB_GLOBAL) {
      // All global symbols created by the VM are currently object symbols.
      Expect.equals(SymbolType.STT_OBJECT, symbol.type);
      Expect.isTrue(symbol.name.startsWith('_kDart'),
          'Unexpected symbol name ${symbol.name}');
      Expect.isFalse(_uniqueSuffixRegexp.hasMatch(symbol.name),
          'Global VM symbols should have no numeric suffix');
      continue;
    }
    if (symbol.type == SymbolType.STT_FUNC ||
        symbol.type == SymbolType.STT_SECTION) {
      // Currently we don't do any additional checking on these.
      continue;
    }
    if (symbol.type != SymbolType.STT_OBJECT) {
      Expect.fail('Unexpected symbol type ${symbol.type}');
    }
    // The name of object symbols are prefixed with the type of the object. If
    // there is useful additional information, the additional information is
    // provided after the type in parentheses.
    int objectTypeEnd = symbol.name.indexOf(' (');
    final objectType = objectTypeEnd > 0
        ? symbol.name.substring(0, objectTypeEnd)
        : symbol.name;

    switch (objectType) {
      // Used for entries in the non-clustered portion of the read-only data
      // section that don't correspond to a specific Dart object.
      case 'RawBytes':
      // Currently the only types of objects written to the non-clustered
      // portion of the read-only data section.
      case 'OneByteString':
      case 'TwoByteString':
      case 'CodeSourceMap':
      case 'PcDescriptors':
      case 'CompressedStackMaps':
        break;
      // In assembly snapshots, we use local object symbols to initialize the
      // InstructionsSection header with the right offset to the BSS section.
      case '_kDartVmSnapshotBss':
      case '_kDartIsolateSnapshotBss':
        Expect.isTrue(isAssembled);
        break;
      default:
        Expect.fail('unexpected object type $objectType in "${symbol.name}"');
    }
  }
}

void checkSymbols(List<Symbol> snapshotSymbols, List<Symbol> debugInfoSymbols,
    {bool isAssembled}) {
  // All symbols in the separate debugging info are created by the VM.
  Expect.isNotEmpty(debugInfoSymbols);
  checkVMSymbolsAreValid(debugInfoSymbols,
      source: 'debug info', isAssembled: isAssembled);
  if (snapshotSymbols == null) return;
  List<Symbol> checkedSnapshotSymbols = snapshotSymbols;
  if (isAssembled) {
    final names = debugInfoSymbols.map((s) => s.name).toSet();
    // All VM-generated symbols should have unique names in assembled output.
    Expect.equals(names.length, debugInfoSymbols.length);
    // For assembled snapshots, we may have symbols that are created by the
    // assembler and not the VM, so ignore those symbols. Since all VM symbols
    // have unique names when generating assembly, we just check that the
    // debug info has a symbol with the same name.
    checkedSnapshotSymbols = <Symbol>[];
    for (final symbol in snapshotSymbols) {
      if (names.contains(symbol.name)) {
        checkedSnapshotSymbols.add(symbol);
      }
    }
  }
  checkVMSymbolsAreValid(checkedSnapshotSymbols,
      source: 'snapshot', isAssembled: isAssembled);
}

void checkElf(Elf snapshot, Elf debugInfo, {bool isAssembled}) {
  // All symbol tables have an initial entry with zero-valued fields.
  final snapshotDynamicSymbols = snapshot?.dynamicSymbols?.skip(1)?.toList();
  final debugDynamicSymbols = debugInfo.dynamicSymbols.skip(1).toList();
  final snapshotStaticSymbols = snapshot?.staticSymbols?.skip(1)?.toList();
  final debugStaticSymbols = debugInfo.staticSymbols.skip(1).toList();

  // First, do our general round of checks against each group of tables.
  checkSymbols(snapshotDynamicSymbols, debugDynamicSymbols,
      isAssembled: isAssembled);
  checkSymbols(snapshotStaticSymbols, debugStaticSymbols,
      isAssembled: isAssembled);

  // Now do some additional spot checks to make sure we actually haven't missed
  // generating some expected VM symbols by examining the debug info tables,
  // which only contain VM generated symbols.

  // For the dynamic symbol tables, we expect that all VM symbols are global
  // object symbols.
  for (final symbol in debugDynamicSymbols) {
    Expect.equals(symbol.bind, SymbolBinding.STB_GLOBAL,
        'Expected all global symbols in the dynamic table, got $symbol');
    Expect.equals(symbol.type, SymbolType.STT_OBJECT,
        'Expected all object symbols in the dynamic table, got $symbol');
  }

  final debugLocalSymbols =
      debugStaticSymbols.where((s) => s.bind == SymbolBinding.STB_LOCAL);
  final debugLocalObjectSymbols =
      debugLocalSymbols.where((s) => s.type == SymbolType.STT_OBJECT);
  // We should be generating at least _some_ local object symbols, since we're
  // using the --add-readonly-data-symbols flag.
  Expect.isNotEmpty(debugLocalObjectSymbols);

  // We expect exactly two local object symbols with names starting with
  // 'RawBytes'.
  int rawBytesSeen = debugLocalObjectSymbols.fold<int>(
      0, (i, s) => i + (s.name.startsWith('RawBytes') ? 1 : 0));
  Expect.equals(2, rawBytesSeen,
      'saw $rawBytesSeen (!= 2) RawBytes local object symbols');

  // All snapshots include at least one (and likely many) duplicate local
  // symbols. For assembly snapshots and their separate debugging information,
  // these symbols will have a numeric suffix to make them unique. In
  // direct-to-ELF snapshots and their separate debugging information, we allow
  // duplicate symbol names and thus there should be no numeric suffixes.
  bool sawUniqueSuffix = false;
  for (final symbol in debugLocalSymbols) {
    if (_uniqueSuffixRegexp.hasMatch(symbol.name)) {
      if (!isAssembled) {
        Expect.fail('Saw numeric suffix on symbol: $symbol');
      }
      sawUniqueSuffix = true;
    }
  }
  if (isAssembled) {
    Expect.isTrue(sawUniqueSuffix, 'No numeric suffixes seen');
  }
}
