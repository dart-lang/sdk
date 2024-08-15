// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that the flag for --dwarf-stack-traces given at AOT
// compile-time will be used at runtime (irrespective if other values were
// passed to the runtime).

import "dart:async";
import "dart:io";

import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:native_stack_traces/src/macho.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'use_flag_test_helper.dart';
import 'use_dwarf_stack_traces_flag_helper.dart';

Future<void> main() async {
  await runTests(
      'dwarf-flag-test',
      path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
          'use_dwarf_stack_traces_flag_program.dart'),
      runNonDwarf,
      runElf,
      runAssembly);
}

Future<NonDwarfState> runNonDwarf(String tempDir, String scriptDill) async {
  final scriptNonDwarfSnapshot = path.join(tempDir, 'non_dwarf.so');

  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--no-dwarf-stack-traces-mode',
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptNonDwarfSnapshot',
    scriptDill,
  ]);

  // Run the resulting non-Dwarf-AOT compiled script.
  final outputWithOppositeFlag =
      (await runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    scriptNonDwarfSnapshot,
    scriptDill,
  ]));
  final output = (await runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    scriptNonDwarfSnapshot,
    scriptDill,
  ]));

  return NonDwarfState(output, outputWithOppositeFlag);
}

class DwarfElfState extends ElfState<Dwarf> {
  DwarfElfState(super.snapshot, super.debugInfo, super.output,
      super.outputWithOppositeFlag);

  @override
  Future<void> check(Trace trace, Dwarf dwarf) =>
      compareTraces(trace, output, outputWithOppositeFlag, dwarf);
}

Future<DwarfElfState> runElf(String tempDir, String scriptDill) async {
  final snapshotPath = path.join(tempDir, 'dwarf.so');
  final debugInfoPath = path.join(tempDir, 'debug_info.so');
  await run(genSnapshot, <String>[
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$debugInfoPath',
    '--snapshot-kind=app-aot-elf',
    '--elf=$snapshotPath',
    scriptDill,
  ]);

  final snapshot = Dwarf.fromFile(snapshotPath)!;
  final debugInfo = Dwarf.fromFile(debugInfoPath)!;

  // Run the resulting Dwarf-AOT compiled script.

  final output = await runTestProgram(dartPrecompiledRuntime,
      <String>['--dwarf-stack-traces-mode', snapshotPath, scriptDill]);
  final outputWithOppositeFlag = await runTestProgram(dartPrecompiledRuntime,
      <String>['--no-dwarf-stack-traces-mode', snapshotPath, scriptDill]);

  return DwarfElfState(snapshot, debugInfo, output, outputWithOppositeFlag);
}

class DwarfAssemblyState extends AssemblyState<Dwarf> {
  DwarfAssemblyState(super.snapshot, super.debugInfo, super.output,
      super.outputWithOppositeFlag,
      [super.singleArch, super.multiArch]);

  @override
  Future<void> check(Trace trace, Dwarf dwarf) =>
      compareTraces(trace, output, outputWithOppositeFlag, dwarf,
          fromAssembly: true);
}

Future<DwarfAssemblyState?> runAssembly(
    String tempDir, String scriptDill) async {
  if (skipAssembly != false) return null;

  final asmPath = path.join(tempDir, 'dwarf_assembly.S');
  final debugInfoPath = path.join(tempDir, 'dwarf_assembly_info.so');
  final snapshotPath = path.join(tempDir, 'dwarf_assembly.so');
  // We get a separate .dSYM bundle on MacOS.
  var debugSnapshotPath = snapshotPath + (Platform.isMacOS ? '.dSYM' : '');

  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$debugInfoPath',
    '--snapshot-kind=app-aot-assembly',
    '--assembly=$asmPath',
    scriptDill,
  ]);

  final debugInfo = Dwarf.fromFile(debugInfoPath)!;

  await assembleSnapshot(asmPath, snapshotPath, debug: true);

  // Run the resulting Dwarf-AOT compiled script.
  final output = await runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    snapshotPath,
    scriptDill,
  ]);
  final outputWithOppositeFlag =
      await runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    snapshotPath,
    scriptDill,
  ]);

  // Get the shared object path inside the .dSYM after compilation on MacOS.
  debugSnapshotPath = MachO.handleDSYM(debugSnapshotPath);
  final snapshot = Dwarf.fromFile(debugSnapshotPath)!;

  Dwarf? singleArchSnapshot;
  Dwarf? multiArchSnapshot;
  if (skipUniversalBinary == false) {
    // Create empty MachO files (just a header) for each of the possible
    // architectures.
    final emptyFiles = <String, String>{};
    for (final arch in machOArchNames.values) {
      // Don't create an empty file for the current architecture.
      if (arch == dartNameForCurrentArchitecture) continue;
      final contents = emptyMachOForArchitecture(arch)!;
      final emptyPath = path.join(tempDir, "empty_$arch.so");
      await File(emptyPath).writeAsBytes(contents, flush: true);
      emptyFiles[arch] = emptyPath;
    }

    final singleArchSnapshotPath = path.join(tempDir, "ub-single");
    await run(lipo, <String>[
      debugSnapshotPath,
      '-create',
      '-output',
      singleArchSnapshotPath,
    ]);
    singleArchSnapshot = Dwarf.fromFile(singleArchSnapshotPath)!;

    final multiArchSnapshotPath = path.join(tempDir, "ub-multiple");
    await run(lipo, <String>[
      ...emptyFiles.values,
      debugSnapshotPath,
      '-create',
      '-output',
      multiArchSnapshotPath,
    ]);
    multiArchSnapshot = Dwarf.fromFile(multiArchSnapshotPath)!;
  }

  return DwarfAssemblyState(snapshot, debugInfo, output, outputWithOppositeFlag,
      singleArchSnapshot, multiArchSnapshot);
}

Future<void> compareTraces(List<String> nonDwarfTrace, DwarfTestOutput output1,
    DwarfTestOutput output2, Dwarf dwarf,
    {bool fromAssembly = false}) async {
  final header1 = StackTraceHeader.fromLines(output1.trace);
  print('Header1 = $header1');
  checkHeader(header1);
  final header2 = StackTraceHeader.fromLines(output2.trace);
  print('Header2 = $header1');
  checkHeader(header2);

  // For DWARF stack traces, we can't guarantee that the stack traces are
  // textually equal on all platforms, but if we retrieve the PC offsets
  // out of the stack trace, those should be equal.
  final tracePCOffsets1 = collectPCOffsets(output1.trace);
  final tracePCOffsets2 = collectPCOffsets(output2.trace);
  expect(tracePCOffsets2, equals(tracePCOffsets1));
  expect(tracePCOffsets1, isNotEmpty);
  checkRootUnitAssumptions(output1, output2, dwarf,
      sampleOffset: tracePCOffsets1.first, matchingBuildIds: !fromAssembly);

  final decoder = DwarfStackTraceDecoder(dwarf);
  final translatedDwarfTrace1 =
      await Stream.fromIterable(output1.trace).transform(decoder).toList();

  checkTranslatedTrace(nonDwarfTrace, translatedDwarfTrace1);

  // Since we compiled directly to ELF, there should be a DSO base address
  // in the stack trace header and 'virt' markers in the stack frames.

  // The offsets of absolute addresses from their respective DSO base
  // should be the same for both traces.
  final dsoBase1 = dsoBaseAddresses(output1.trace).single;
  final dsoBase2 = dsoBaseAddresses(output2.trace).single;

  final absTrace1 = absoluteAddresses(output1.trace);
  final absTrace2 = absoluteAddresses(output2.trace);

  final relocatedFromDso1 = absTrace1.map((a) => a - dsoBase1);
  final relocatedFromDso2 = absTrace2.map((a) => a - dsoBase2);

  expect(relocatedFromDso2, equals(relocatedFromDso1));

  // We don't print 'virt' relocated addresses when running assembled snapshots.
  if (fromAssembly) return;

  // The relocated addresses marked with 'virt' should match between the
  // different runs, and they should also match the relocated address
  // calculated from the PCOffset for each frame as well as the relocated
  // address for each frame calculated using the respective DSO base.
  final virtTrace1 = explicitVirtualAddresses(output1.trace);
  final virtTrace2 = explicitVirtualAddresses(output2.trace);

  expect(virtTrace2, equals(virtTrace1));

  expect(tracePCOffsets1.map((o) => o.virtualAddressIn(dwarf)),
      equals(virtTrace1));
  expect(tracePCOffsets2.map((o) => o.virtualAddressIn(dwarf)),
      equals(virtTrace2));

  expect(relocatedFromDso1, equals(virtTrace1));
  expect(relocatedFromDso2, equals(virtTrace2));
}
