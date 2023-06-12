// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that the flag for --dwarf-stack-traces given at AOT
// compile-time will be used at runtime (irrespective if other values were
// passed to the runtime).

import "dart:async";
import "dart:convert";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:native_stack_traces/src/macho.dart';
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

  await withTempDir('dwarf-flag-test', (String tempDir) async {
    // We have to use the program in its original location so it can use
    // the dart:_internal library (as opposed to adding it as an OtherResources
    // option to the test).
    final script = path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
        'use_dwarf_stack_traces_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    // Run the AOT compiler with/without Dwarf stack traces.
    final scriptDwarfSnapshot = path.join(tempDir, 'dwarf.so');
    final scriptNonDwarfSnapshot = path.join(tempDir, 'non_dwarf.so');
    final scriptDwarfDebugInfo = path.join(tempDir, 'debug_info.so');
    await Future.wait(<Future>[
      run(genSnapshot, <String>[
        // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
        // the latter is a handler that sets the former and also may change
        // other flags. This way, we limit the difference between the two
        // snapshots and also directly test the flag saved as a VM global flag.
        '--dwarf-stack-traces-mode',
        '--save-debugging-info=$scriptDwarfDebugInfo',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptDwarfSnapshot',
        scriptDill,
      ]),
      run(genSnapshot, <String>[
        '--no-dwarf-stack-traces-mode',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptNonDwarfSnapshot',
        scriptDill,
      ]),
    ]);

    // Run the resulting Dwarf-AOT compiled script.

    final output1 = await runTestProgram(dartPrecompiledRuntime,
        <String>['--dwarf-stack-traces-mode', scriptDwarfSnapshot, scriptDill]);
    final output2 = await runTestProgram(dartPrecompiledRuntime, <String>[
      '--no-dwarf-stack-traces-mode',
      scriptDwarfSnapshot,
      scriptDill
    ]);

    // Run the resulting non-Dwarf-AOT compiled script.
    final nonDwarfTrace1 =
        (await runTestProgram(dartPrecompiledRuntime, <String>[
      '--dwarf-stack-traces-mode',
      scriptNonDwarfSnapshot,
      scriptDill,
    ]))
            .trace;
    final nonDwarfTrace2 =
        (await runTestProgram(dartPrecompiledRuntime, <String>[
      '--no-dwarf-stack-traces-mode',
      scriptNonDwarfSnapshot,
      scriptDill,
    ]))
            .trace;

    // Ensure the result is based off the flag passed to gen_snapshot, not
    // the one passed to the runtime.
    Expect.deepEquals(nonDwarfTrace1, nonDwarfTrace2);

    // Check with DWARF from separate debugging information.
    await compareTraces(nonDwarfTrace1, output1, output2, scriptDwarfDebugInfo);
    // Check with DWARF in generated snapshot.
    await compareTraces(nonDwarfTrace1, output1, output2, scriptDwarfSnapshot);

    await testAssembly(tempDir, scriptDill, nonDwarfTrace1);
  });
}

const _lipoBinary = "/usr/bin/lipo";

Future<void> testAssembly(
    String tempDir, String scriptDill, List<String> nonDwarfTrace) async {
  // Currently there are no appropriate buildtools on the simulator trybots as
  // normally they compile to ELF and don't need them for compiling assembly
  // snapshots.
  if (isSimulator || (!Platform.isLinux && !Platform.isMacOS)) return;

  final scriptAssembly = path.join(tempDir, 'dwarf_assembly.S');
  final scriptDwarfAssemblyDebugInfo =
      path.join(tempDir, 'dwarf_assembly_info.so');
  final scriptDwarfAssemblySnapshot = path.join(tempDir, 'dwarf_assembly.so');
  // We get a separate .dSYM bundle on MacOS.
  final scriptDwarfAssemblyDebugSnapshot =
      scriptDwarfAssemblySnapshot + (Platform.isMacOS ? '.dSYM' : '');

  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$scriptDwarfAssemblyDebugInfo',
    '--snapshot-kind=app-aot-assembly',
    '--assembly=$scriptAssembly',
    scriptDill,
  ]);

  await assembleSnapshot(scriptAssembly, scriptDwarfAssemblySnapshot,
      debug: true);

  // Run the resulting Dwarf-AOT compiled script.
  final assemblyOutput1 = await runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    scriptDwarfAssemblySnapshot,
    scriptDill,
  ]);
  final assemblyOutput2 = await runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    scriptDwarfAssemblySnapshot,
    scriptDill,
  ]);

  // Check with DWARF in assembled snapshot.
  await compareTraces(nonDwarfTrace, assemblyOutput1, assemblyOutput2,
      scriptDwarfAssemblyDebugSnapshot,
      fromAssembly: true);
  // Check with DWARF from separate debugging information.
  await compareTraces(nonDwarfTrace, assemblyOutput1, assemblyOutput2,
      scriptDwarfAssemblyDebugInfo,
      fromAssembly: true);

  // Next comes tests for MacOS universal binaries.
  if (!Platform.isMacOS) return;

  // Test this before continuing.
  if (!await File(_lipoBinary).exists()) {
    Expect.fail("missing lipo binary");
  }

  // Create empty MachO files (just a header) for each of the possible
  // architectures.
  final emptyFiles = <String, String>{};
  for (final arch in _machOArchNames.values) {
    // Don't create an empty file for the current architecture.
    if (arch == dartNameForCurrentArchitecture) continue;
    final contents = emptyMachOForArchitecture(arch);
    Expect.isNotNull(contents);
    final emptyPath = path.join(tempDir, "empty_$arch.so");
    await File(emptyPath).writeAsBytes(contents!, flush: true);
    emptyFiles[arch] = emptyPath;
  }

  Future<void> testUniversalBinary(
      String binaryPath, List<String> machoFiles) async {
    await run(
        _lipoBinary, <String>[...machoFiles, '-create', '-output', binaryPath]);
    await compareTraces(
        nonDwarfTrace, assemblyOutput1, assemblyOutput2, binaryPath,
        fromAssembly: true);
  }

  final scriptDwarfAssemblyDebugSnapshotFile =
      MachO.handleDSYM(scriptDwarfAssemblyDebugSnapshot);
  await testUniversalBinary(path.join(tempDir, "ub-single"),
      <String>[scriptDwarfAssemblyDebugSnapshotFile]);
  await testUniversalBinary(path.join(tempDir, "ub-multiple"),
      <String>[...emptyFiles.values, scriptDwarfAssemblyDebugSnapshotFile]);
}

class DwarfTestOutput {
  final List<String> trace;
  final int allocateObjectInstructionsOffset;

  DwarfTestOutput(this.trace, this.allocateObjectInstructionsOffset);
}

Future<void> compareTraces(List<String> nonDwarfTrace, DwarfTestOutput output1,
    DwarfTestOutput output2, String dwarfPath,
    {bool fromAssembly = false}) async {
  // For DWARF stack traces, we can't guarantee that the stack traces are
  // textually equal on all platforms, but if we retrieve the PC offsets
  // out of the stack trace, those should be equal.
  final tracePCOffsets1 = collectPCOffsets(output1.trace);
  final tracePCOffsets2 = collectPCOffsets(output2.trace);
  Expect.deepEquals(tracePCOffsets1, tracePCOffsets2);

  if (tracePCOffsets1.isNotEmpty) {
    final exampleOffset = tracePCOffsets1.first;

    // We run the test program on the same host OS as the test, so any of the
    // PCOffsets above should have this information.
    Expect.isNotNull(exampleOffset.os);
    Expect.isNotNull(exampleOffset.architecture);
    Expect.isNotNull(exampleOffset.usingSimulator);
    Expect.isNotNull(exampleOffset.compressedPointers);

    Expect.equals(exampleOffset.os, Platform.operatingSystem);
    final archString = '${exampleOffset.usingSimulator! ? 'SIM' : ''}'
        '${exampleOffset.architecture!.toUpperCase()}'
        '${exampleOffset.compressedPointers! ? 'C' : ''}';
    final baseBuildDir = path.basename(buildDir);
    Expect.isTrue(baseBuildDir.endsWith(archString),
        'Expected $baseBuildDir to end with $archString');
  }

  // Check that translating the DWARF stack trace (without internal frames)
  // matches the symbolic stack trace.
  print("Reading DWARF info from ${dwarfPath}");
  final dwarf = Dwarf.fromFile(dwarfPath);
  Expect.isNotNull(dwarf);

  // Check that build IDs match for traces from running ELF snapshots.
  if (!fromAssembly) {
    final dwarfBuildId = dwarf!.buildId();
    Expect.isNotNull(dwarfBuildId);
    print('Dwarf build ID: "${dwarfBuildId!}"');
    // We should never generate an all-zero build ID.
    Expect.notEquals(dwarfBuildId, "00000000000000000000000000000000");
    // This is a common failure case as well, when HashBitsContainer ends up
    // hashing over seemingly empty sections.
    Expect.notEquals(dwarfBuildId, "01000000010000000100000001000000");
    final buildId1 = buildId(output1.trace);
    Expect.isFalse(buildId1.isEmpty);
    print('Trace 1 build ID: "${buildId1}"');
    Expect.equals(dwarfBuildId, buildId1);
    final buildId2 = buildId(output2.trace);
    Expect.isFalse(buildId2.isEmpty);
    print('Trace 2 build ID: "${buildId2}"');
    Expect.equals(dwarfBuildId, buildId2);
  } else {
    // Just check that the build IDs exist in the traces and are the same.
    final buildId1 = buildId(output1.trace);
    Expect.isFalse(buildId1.isEmpty, 'Could not find build ID in first trace');
    print('Trace 1 build ID: "${buildId1}"');
    final buildId2 = buildId(output2.trace);
    Expect.isFalse(buildId2.isEmpty, 'Could not find build ID in second trace');
    print('Trace 2 build ID: "${buildId2}"');
    Expect.equals(buildId1, buildId2);
  }

  final decoder = DwarfStackTraceDecoder(dwarf!);
  final translatedDwarfTrace1 =
      await Stream.fromIterable(output1.trace).transform(decoder).toList();

  final allocateObjectPCOffset1 = PCOffset(
      output1.allocateObjectInstructionsOffset, InstructionsSection.isolate);
  final allocateObjectPCOffset2 = PCOffset(
      output2.allocateObjectInstructionsOffset, InstructionsSection.isolate);

  print('Offset of first stub address is $allocateObjectPCOffset1');
  print('Offset of second stub address is $allocateObjectPCOffset2');

  final allocateObjectCallInfo1 = dwarf.callInfoForPCOffset(
      allocateObjectPCOffset1,
      includeInternalFrames: true);
  final allocateObjectCallInfo2 = dwarf.callInfoForPCOffset(
      allocateObjectPCOffset2,
      includeInternalFrames: true);

  Expect.isNotNull(allocateObjectCallInfo1);
  Expect.isNotNull(allocateObjectCallInfo2);
  Expect.equals(allocateObjectCallInfo1!.length, 1);
  Expect.equals(allocateObjectCallInfo2!.length, 1);
  Expect.isTrue(
      allocateObjectCallInfo1.first is StubCallInfo, 'is not a StubCall');
  Expect.isTrue(
      allocateObjectCallInfo2.first is StubCallInfo, 'is not a StubCall');
  final stubCall1 = allocateObjectCallInfo1.first as StubCallInfo;
  final stubCall2 = allocateObjectCallInfo2.first as StubCallInfo;
  Expect.equals(stubCall1.name, stubCall2.name);
  Expect.contains('AllocateObject', stubCall1.name);
  Expect.contains('AllocateObject', stubCall2.name);

  print("Successfully matched AllocateObject stub addresses");
  print("");

  final translatedStackFrames = onlySymbolicFrameLines(translatedDwarfTrace1);
  final originalStackFrames = onlySymbolicFrameLines(nonDwarfTrace);

  print('Stack frames from translated non-symbolic stack trace:');
  translatedStackFrames.forEach(print);
  print('');

  print('Stack frames from original symbolic stack trace:');
  originalStackFrames.forEach(print);
  print('');

  Expect.isTrue(translatedStackFrames.length > 0);
  Expect.isTrue(originalStackFrames.length > 0);

  // In symbolic mode, we don't store column information to avoid an increase
  // in size of CodeStackMaps. Thus, we need to strip any columns from the
  // translated non-symbolic stack to compare them via equality.
  final columnStrippedTranslated = removeColumns(translatedStackFrames);

  print('Stack frames from translated non-symbolic stack trace, no columns:');
  columnStrippedTranslated.forEach(print);
  print('');

  Expect.deepEquals(columnStrippedTranslated, originalStackFrames);

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

  Expect.deepEquals(relocatedFromDso1, relocatedFromDso2);

  // We don't print 'virt' relocated addresses when running assembled snapshots.
  if (fromAssembly) return;

  // The relocated addresses marked with 'virt' should match between the
  // different runs, and they should also match the relocated address
  // calculated from the PCOffset for each frame as well as the relocated
  // address for each frame calculated using the respective DSO base.
  final virtTrace1 = explicitVirtualAddresses(output1.trace);
  final virtTrace2 = explicitVirtualAddresses(output2.trace);

  Expect.deepEquals(virtTrace1, virtTrace2);

  Expect.deepEquals(
      virtTrace1, tracePCOffsets1.map((o) => o.virtualAddressIn(dwarf)));
  Expect.deepEquals(
      virtTrace2, tracePCOffsets2.map((o) => o.virtualAddressIn(dwarf)));

  Expect.deepEquals(virtTrace1, relocatedFromDso1);
  Expect.deepEquals(virtTrace2, relocatedFromDso2);
}

Future<DwarfTestOutput> runTestProgram(
    String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode == 0) {
    throw 'Command did not fail with non-zero exit code';
  }
  Expect.isTrue(result.stdout.isNotEmpty);
  Expect.isTrue(result.stderr.isNotEmpty);

  return DwarfTestOutput(
      LineSplitter.split(result.stderr).toList(), int.parse(result.stdout));
}

final _buildIdRE = RegExp(r"build_id: '([a-f\d]+)'");
String buildId(Iterable<String> lines) {
  for (final line in lines) {
    final match = _buildIdRE.firstMatch(line);
    if (match != null) {
      return match.group(1)!;
    }
  }
  return '';
}

final _symbolicFrameRE = RegExp(r'^#\d+\s+');

Iterable<String> onlySymbolicFrameLines(Iterable<String> lines) {
  return lines.where((line) => _symbolicFrameRE.hasMatch(line));
}

final _columnsRE = RegExp(r'[(](.*:\d+):\d+[)]');

Iterable<String> removeColumns(Iterable<String> lines) sync* {
  for (final line in lines) {
    final match = _columnsRE.firstMatch(line);
    if (match != null) {
      yield line.replaceRange(match.start, match.end, '(${match.group(1)!})');
    } else {
      yield line;
    }
  }
}

Iterable<int> parseUsingAddressRegExp(RegExp re, Iterable<String> lines) sync* {
  for (final line in lines) {
    final match = re.firstMatch(line);
    if (match != null) {
      yield int.parse(match.group(1)!, radix: 16);
    }
  }
}

final _absRE = RegExp(r'abs ([a-f\d]+)');

Iterable<int> absoluteAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_absRE, lines);

final _virtRE = RegExp(r'virt ([a-f\d]+)');

Iterable<int> explicitVirtualAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_virtRE, lines);

final _dsoBaseRE = RegExp(r'isolate_dso_base: ([a-f\d]+)');

Iterable<int> dsoBaseAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_dsoBaseRE, lines);

// We only list architectures supported by the current CpuType enum in
// pkg:native_stack_traces/src/macho.dart.
const _machOArchNames = <String, String>{
  "ARM": "arm",
  "ARM64": "arm64",
  "IA32": "ia32",
  "X64": "x64",
};

String? get dartNameForCurrentArchitecture {
  for (final entry in _machOArchNames.entries) {
    if (buildDir.endsWith(entry.key)) {
      return entry.value;
    }
  }
  return null;
}
