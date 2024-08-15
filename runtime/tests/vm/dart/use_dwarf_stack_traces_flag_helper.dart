// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper methods and definitions used in the use_dwarf_stack_traces_flag tests.

import "dart:async";
import "dart:convert";
import "dart:io";

import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'use_flag_test_helper.dart';

/// Returns false if tests involving assembly snapshots should be run
/// and a String describing why the tests should be skipped otherwise.
Object get skipAssembly {
  // Currently there are no appropriate buildtools on the simulator trybots as
  // normally they compile to ELF and don't need them for compiling assembly
  // snapshots.
  if (isSimulator) {
    return "running on a simulated architecture";
  }
  return (Platform.isLinux || Platform.isMacOS)
      ? false
      : "no process for assembling snapshots on this platform";
}

/// Returns false if tests involving MacOS universal binaries should be run
/// and a String describing why the tests should be skipped otherwise.
Object get skipUniversalBinary {
  final assemblySkipped = skipAssembly;
  if (assemblySkipped != false) return assemblySkipped;
  return Platform.isMacOS ? false : "only valid for MacOS";
}

typedef Trace = List<String>;

class DwarfTestOutput {
  final Trace trace;
  final int allocateObjectStart;
  final int allocateObjectEnd;

  DwarfTestOutput(this.trace, this.allocateObjectStart, this.allocateObjectEnd);
}

class NonDwarfState {
  final DwarfTestOutput output;
  final DwarfTestOutput outputWithOppositeFlag;

  NonDwarfState(this.output, this.outputWithOppositeFlag);

  void check() => expect(outputWithOppositeFlag.trace, equals(output.trace));
}

abstract class ElfState<T> {
  final T snapshot;
  final T debugInfo;
  final DwarfTestOutput output;
  final DwarfTestOutput outputWithOppositeFlag;

  ElfState(
      this.snapshot, this.debugInfo, this.output, this.outputWithOppositeFlag);

  Future<void> check(Trace trace, T t);
}

abstract class AssemblyState<T> {
  final T snapshot;
  final T debugInfo;
  final DwarfTestOutput output;
  final DwarfTestOutput outputWithOppositeFlag;
  final T? singleArch;
  final T? multiArch;

  AssemblyState(
      this.snapshot, this.debugInfo, this.output, this.outputWithOppositeFlag,
      [this.singleArch, this.multiArch]);

  Future<void> check(Trace trace, T t);
}

abstract class UniversalBinaryState<T> {
  final T singleArch;
  final T multiArch;

  UniversalBinaryState(this.singleArch, this.multiArch);

  Future<void> checkSingleArch(Trace trace, AssemblyState assemblyState);
  Future<void> checkMultiArch(Trace trace, AssemblyState assemblyState);
}

Future<void> runTests<T>(
    String tempPrefix,
    String scriptPath,
    Future<NonDwarfState> Function(String, String) runNonDwarf,
    Future<ElfState<T>> Function(String, String) runElf,
    Future<AssemblyState<T>?> Function(String, String) runAssembly) async {
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

    final nonDwarfState = await runNonDwarf(tempDir, scriptDill);
    final elfState = await runElf(tempDir, scriptDill);
    final assemblyState = await runAssembly(tempDir, scriptDill);

    test('Testing symbolic traces', nonDwarfState.check);

    final nonDwarfTrace = nonDwarfState.output.trace;

    test('Testing ELF traces with separate debugging info',
        () async => await elfState.check(nonDwarfTrace, elfState.debugInfo));

    test('Testing ELF traces with original snapshot',
        () async => await elfState.check(nonDwarfTrace, elfState.snapshot));

    test('Testing assembly traces with separate debugging info', () async {
      expect(assemblyState, isNotNull);
      await assemblyState!.check(nonDwarfTrace, assemblyState.debugInfo);
    }, skip: skipAssembly);

    test('Testing assembly traces with debug snapshot ', () async {
      expect(assemblyState, isNotNull);
      await assemblyState!.check(nonDwarfTrace, assemblyState.snapshot);
    }, skip: skipAssembly);

    test('Testing single-architecture universal binary', () async {
      expect(assemblyState, isNotNull);
      expect(assemblyState!.singleArch, isNotNull);
      await assemblyState.check(nonDwarfTrace, assemblyState.singleArch!);
    }, skip: skipUniversalBinary);

    test('Testing multi-architecture universal binary', () async {
      expect(assemblyState, isNotNull);
      expect(assemblyState!.multiArch, isNotNull);
      await assemblyState.check(nonDwarfTrace, assemblyState.multiArch!);
    }, skip: skipUniversalBinary);
  });
}

void checkHeader(StackTraceHeader header) {
  // These should be all available.
  expect(header.vmStart, isNotNull);
  expect(header.isolateStart, isNotNull);
  expect(header.isolateDsoBase, isNotNull);
  expect(header.buildId, isNotNull);
  expect(header.os, isNotNull);
  expect(header.architecture, isNotNull);
  expect(header.usingSimulator, isNotNull);
  expect(header.compressedPointers, isNotNull);
}

void checkRootUnitAssumptions(
    DwarfTestOutput output1, DwarfTestOutput output2, Dwarf rootDwarf,
    {required PCOffset sampleOffset, bool matchingBuildIds = true}) {
  // We run the test program on the same host OS as the test, so any
  // PCOffset from the trace should have this information.
  expect(sampleOffset.os, isNotNull);
  expect(sampleOffset.architecture, isNotNull);
  expect(sampleOffset.usingSimulator, isNotNull);
  expect(sampleOffset.compressedPointers, isNotNull);

  expect(sampleOffset.os, equals(Platform.operatingSystem));
  final archString = '${sampleOffset.usingSimulator! ? 'SIM' : ''}'
      '${sampleOffset.architecture!.toUpperCase()}'
      '${sampleOffset.compressedPointers! ? 'C' : ''}';
  final baseBuildDir = path.basename(buildDir);
  expect(baseBuildDir, endsWith(archString));

  // Check that the build IDs exist in the traces and are the same.
  final buildId1 = buildId(output1.trace);
  expect(buildId1, isNotEmpty);
  print('Trace 1 build ID: "${buildId1}"');
  final buildId2 = buildId(output2.trace);
  expect(buildId2, isNotEmpty);
  print('Trace 2 build ID: "${buildId2}"');
  expect(buildId2, equals(buildId1));

  if (matchingBuildIds) {
    // The build ID in the traces should be the same as the DWARF build ID
    // when the ELF was generated by gen_snapshot.
    final dwarfBuildId = rootDwarf.buildId();
    expect(dwarfBuildId, isNotNull);
    print('Dwarf build ID: "${dwarfBuildId!}"');
    // We should never generate an all-zero build ID.
    expect(dwarfBuildId, isNot("00000000000000000000000000000000"));
    // This is a common failure case as well, when HashBitsContainer ends up
    // hashing over seemingly empty sections.
    expect(dwarfBuildId, isNot("01000000010000000100000001000000"));
    expect(buildId1, equals(dwarfBuildId));
    expect(buildId2, equals(dwarfBuildId));
  }

  final allocateObjectStart = output1.allocateObjectStart;
  final allocateObjectEnd = output1.allocateObjectEnd;
  expect(output2.allocateObjectStart, equals(allocateObjectStart));
  expect(output2.allocateObjectEnd, equals(allocateObjectEnd));

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
  expect(allocateObjectEnd - allocateObjectStart, greaterThanOrEqualTo(16),
      reason: 'midpoint of stub may be in bare payload padding');
  checkAllocateObjectOffset(
      rootDwarf, (allocateObjectStart + allocateObjectEnd) ~/ 2);

  print("Successfully matched AllocateObject stub addresses");
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
  expect(got, equals(expectedValue),
      reason: 'address is ${expectedValue ? 'not within' : 'within'} '
          'the AllocateObject stub');
}

void checkTranslatedTrace(List<String> nonDwarfTrace, List<String> dwarfTrace) {
  final translatedStackFrames = onlySymbolicFrameLines(dwarfTrace);
  final originalStackFrames = onlySymbolicFrameLines(nonDwarfTrace);

  print('Stack frames from translated non-symbolic stack trace:');
  print(translatedStackFrames.join('\n'));

  print('Stack frames from original symbolic stack trace:');
  print(originalStackFrames.join('\n'));

  expect(translatedStackFrames, isNotEmpty);
  expect(originalStackFrames, isNotEmpty);

  // In symbolic mode, we don't store column information to avoid an increase
  // in size of CodeStackMaps. Thus, we need to strip any columns from the
  // translated non-symbolic stack to compare them via equality.
  final columnStrippedTranslated = removeColumns(translatedStackFrames);

  print('Stack frames from translated non-symbolic stack trace, no columns:');
  print(columnStrippedTranslated.join('\n'));

  expect(columnStrippedTranslated, equals(originalStackFrames));
}

Future<DwarfTestOutput> runTestProgram(
    String executable, List<String> args) async {
  final result = await runHelper(executable, args);

  if (result.exitCode == 0) {
    throw 'Command did not fail with non-zero exit code';
  }
  if (result.stdout.isEmpty) {
    throw 'Command did not print a stacktrace';
  }

  final stdoutLines = LineSplitter.split(result.stdout).toList();
  if (result.stdout.length < 2) {
    throw 'Command did not print both absolute addresses for stub range';
  }
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
