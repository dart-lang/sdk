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

Future<void> main() async {
  await runTests(
      'dwarf-flag-test',
      path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
          'use_dwarf_stack_traces_flag_program.dart'),
      testNonDwarf,
      testElf,
      testAssembly);
}

Future<void> runTests(
    String tempPrefix,
    String scriptPath,
    Future<List<String>> Function(String, String) testNonDwarf,
    Future<void> Function(String, String, List<String>) testElf,
    Future<void> Function(String, String, List<String>) testAssembly) async {
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

  await withTempDir(tempPrefix, (String tempDir) async {
    // We have to use the program in its original location so it can use
    // the dart:_internal library (as opposed to adding it as an OtherResources
    // option to the test).
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      scriptPath,
    ]);

    final nonDwarfTrace = await testNonDwarf(tempDir, scriptDill);

    await testElf(tempDir, scriptDill, nonDwarfTrace);

    await testAssembly(tempDir, scriptDill, nonDwarfTrace);
  });
}

Future<List<String>> testNonDwarf(String tempDir, String scriptDill) async {
  final scriptNonDwarfSnapshot = path.join(tempDir, 'non_dwarf.so');

  await run(genSnapshot, <String>[
    '--no-dwarf-stack-traces-mode',
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptNonDwarfSnapshot',
    scriptDill,
  ]);

  // Run the resulting non-Dwarf-AOT compiled script.
  final nonDwarfTrace1 = (await runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    scriptNonDwarfSnapshot,
    scriptDill,
  ]))
      .trace;
  final nonDwarfTrace2 = (await runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    scriptNonDwarfSnapshot,
    scriptDill,
  ]))
      .trace;

  // Ensure the result is based off the flag passed to gen_snapshot, not
  // the one passed to the runtime.
  Expect.deepEquals(nonDwarfTrace1, nonDwarfTrace2);

  return nonDwarfTrace1;
}

Future<void> testElf(
    String tempDir, String scriptDill, List<String> nonDwarfTrace) async {
  final scriptDwarfSnapshot = path.join(tempDir, 'dwarf.so');
  final scriptDwarfDebugInfo = path.join(tempDir, 'debug_info.so');
  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$scriptDwarfDebugInfo',
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptDwarfSnapshot',
    scriptDill,
  ]);

  // Run the resulting Dwarf-AOT compiled script.

  final output1 = await runTestProgram(dartPrecompiledRuntime,
      <String>['--dwarf-stack-traces-mode', scriptDwarfSnapshot, scriptDill]);
  final output2 = await runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    scriptDwarfSnapshot,
    scriptDill
  ]);

  // Check with DWARF from separate debugging information.
  await compareTraces(nonDwarfTrace, output1, output2, scriptDwarfDebugInfo);
  // Check with DWARF in generated snapshot.
  await compareTraces(nonDwarfTrace, output1, output2, scriptDwarfSnapshot);
}

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

  // Create empty MachO files (just a header) for each of the possible
  // architectures.
  final emptyFiles = <String, String>{};
  for (final arch in machOArchNames.values) {
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
    await run(lipo, <String>[...machoFiles, '-create', '-output', binaryPath]);
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
  final int allocateObjectStart;
  final int allocateObjectEnd;

  DwarfTestOutput(this.trace, this.allocateObjectStart, this.allocateObjectEnd);
}

Future<void> compareTraces(List<String> nonDwarfTrace, DwarfTestOutput output1,
    DwarfTestOutput output2, String dwarfPath,
    {bool fromAssembly = false}) async {
  final header1 = StackTraceHeader.fromLines(output1.trace);
  print('Header1 = $header1');
  checkHeader(header1);
  final header2 = StackTraceHeader.fromLines(output2.trace);
  print('Header2 = $header1');
  checkHeader(header2);

  // Check that translating the DWARF stack trace (without internal frames)
  // matches the symbolic stack trace.
  print("Reading DWARF info from ${dwarfPath}");
  final dwarf = Dwarf.fromFile(dwarfPath);
  if (dwarf == null) {
    throw 'No DWARF information at $dwarfPath';
  }

  // For DWARF stack traces, we can't guarantee that the stack traces are
  // textually equal on all platforms, but if we retrieve the PC offsets
  // out of the stack trace, those should be equal.
  final tracePCOffsets1 = collectPCOffsets(output1.trace);
  final tracePCOffsets2 = collectPCOffsets(output2.trace);
  Expect.deepEquals(tracePCOffsets1, tracePCOffsets2);

  Expect.isNotEmpty(tracePCOffsets1);
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

void checkHeader(StackTraceHeader header) {
  // These should be all available.
  Expect.isNotNull(header.vmStart);
  Expect.isNotNull(header.isolateStart);
  Expect.isNotNull(header.isolateDsoBase);
  Expect.isNotNull(header.buildId);
  Expect.isNotNull(header.os);
  Expect.isNotNull(header.architecture);
  Expect.isNotNull(header.usingSimulator);
  Expect.isNotNull(header.compressedPointers);
}

void checkRootUnitAssumptions(
    DwarfTestOutput output1, DwarfTestOutput output2, Dwarf rootDwarf,
    {required PCOffset sampleOffset, bool matchingBuildIds = true}) {
  // We run the test program on the same host OS as the test, so any
  // PCOffset from the trace should have this information.
  Expect.isNotNull(sampleOffset.os);
  Expect.isNotNull(sampleOffset.architecture);
  Expect.isNotNull(sampleOffset.usingSimulator);
  Expect.isNotNull(sampleOffset.compressedPointers);

  Expect.equals(sampleOffset.os, Platform.operatingSystem);
  final archString = '${sampleOffset.usingSimulator! ? 'SIM' : ''}'
      '${sampleOffset.architecture!.toUpperCase()}'
      '${sampleOffset.compressedPointers! ? 'C' : ''}';
  final baseBuildDir = path.basename(buildDir);
  Expect.isTrue(baseBuildDir.endsWith(archString),
      'Expected $baseBuildDir to end with $archString');

  // Check that the build IDs exist in the traces and are the same.
  final buildId1 = buildId(output1.trace);
  Expect.isFalse(buildId1.isEmpty, 'Could not find build ID in first trace');
  print('Trace 1 build ID: "${buildId1}"');
  final buildId2 = buildId(output2.trace);
  Expect.isFalse(buildId2.isEmpty, 'Could not find build ID in second trace');
  print('Trace 2 build ID: "${buildId2}"');
  Expect.equals(buildId1, buildId2);

  if (matchingBuildIds) {
    // The build ID in the traces should be the same as the DWARF build ID
    // when the ELF was generated by gen_snapshot.
    final dwarfBuildId = rootDwarf.buildId();
    Expect.isNotNull(dwarfBuildId);
    print('Dwarf build ID: "${dwarfBuildId!}"');
    // We should never generate an all-zero build ID.
    Expect.notEquals(dwarfBuildId, "00000000000000000000000000000000");
    // This is a common failure case as well, when HashBitsContainer ends up
    // hashing over seemingly empty sections.
    Expect.notEquals(dwarfBuildId, "01000000010000000100000001000000");
    Expect.stringEquals(dwarfBuildId, buildId1);
    Expect.stringEquals(dwarfBuildId, buildId2);
  }

  final allocateObjectStart = output1.allocateObjectStart;
  final allocateObjectEnd = output1.allocateObjectEnd;
  Expect.equals(allocateObjectStart, output2.allocateObjectStart);
  Expect.equals(allocateObjectEnd, output2.allocateObjectEnd);

  checkAllocateObjectOffset(rootDwarf, allocateObjectStart);
  // The end of the bare instructions payload may be padded up to word size,
  // so check the maximum possible word size (64 bits) before the end.
  checkAllocateObjectOffset(rootDwarf, allocateObjectEnd - 8);
  // The end should be either in a different stub or not a stub altogether.
  checkAllocateObjectOffset(rootDwarf, allocateObjectEnd, expectedValue: false);
  // The byte before the start should also be in either a different stub or
  // not in a stub altogether.
  checkAllocateObjectOffset(rootDwarf, allocateObjectStart - 1,
      expectedValue: false);
  // Check the midpoint of the stub, as the stub should be large enough that the
  // midpoint won't be in any possible padding.
  Expect.isTrue(allocateObjectEnd - allocateObjectStart >= 16,
      'midpoint of stub may be in bare payload padding');
  checkAllocateObjectOffset(
      rootDwarf, (allocateObjectStart + allocateObjectEnd) ~/ 2);

  print("Successfully matched AllocateObject stub addresses");
  print("");
}

void checkAllocateObjectOffset(Dwarf dwarf, int offset,
    {bool expectedValue = true}) {
  final pcOffset = PCOffset(offset, InstructionsSection.isolate);
  print('Offset of tested stub address is $pcOffset');
  final callInfo =
      dwarf.callInfoForPCOffset(pcOffset, includeInternalFrames: true);
  print('Call info for tested stub address is $callInfo');
  final got = callInfo != null &&
      callInfo.length == 1 &&
      callInfo.single is StubCallInfo &&
      (callInfo.single as StubCallInfo).name.endsWith('AllocateObjectStub');
  Expect.equals(
      expectedValue,
      got,
      'address is ${expectedValue ? 'not within' : 'within'} '
      'the AllocateObject stub');
}

void checkTranslatedTrace(List<String> nonDwarfTrace, List<String> dwarfTrace) {
  final translatedStackFrames = onlySymbolicFrameLines(dwarfTrace);
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
}

Future<DwarfTestOutput> runTestProgram(
    String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode == 0) {
    throw 'Command did not fail with non-zero exit code';
  }
  Expect.isTrue(result.stdout.isNotEmpty);
  Expect.isTrue(result.stderr.isNotEmpty);

  final stdoutLines = LineSplitter.split(result.stdout).toList();
  Expect.isTrue(stdoutLines.length >= 2);
  final start = int.parse(stdoutLines[0]);
  final end = int.parse(stdoutLines[1]);

  return DwarfTestOutput(
      LineSplitter.split(result.stderr).toList(), start, end);
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
const machOArchNames = <String, String>{
  "ARM": "arm",
  "ARM64": "arm64",
  "IA32": "ia32",
  "X64": "x64",
};

String? get dartNameForCurrentArchitecture {
  for (final entry in machOArchNames.entries) {
    if (buildDir.endsWith(entry.key)) {
      return entry.value;
    }
  }
  return null;
}
