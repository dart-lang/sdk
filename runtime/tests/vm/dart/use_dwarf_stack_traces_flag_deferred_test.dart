// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that we can properly resolve non-symbolic stack frames
// involving non-root deferred loading units. It also checks that
// native_stack_traces/src/convert.dart is able to resolve such frames in two
// different cases when applicable:
// * When given a map of unit ids to DWARF objects (all cases)
// * When given an iterable of DWARF objects, in which case it falls back
//   on build ID lookup (direct ELF output only).

import "dart:async";
import "dart:convert";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:native_stack_traces/src/constants.dart' show rootLoadingUnitId;
import 'package:native_stack_traces/src/convert.dart' show LoadingUnit;
import 'package:native_stack_traces/src/macho.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';
import 'use_dwarf_stack_traces_flag_test.dart' as original;

Future<void> main() async {
  await original.runTests(
      'dwarf-flag-deferred-test',
      path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
          'use_dwarf_stack_traces_flag_deferred_program.dart'),
      testNonDwarf,
      testElf,
      testAssembly);
}

Manifest useSnapshotForDwarfPath(Manifest original,
    {String? outputDir, String suffix = ''}) {
  final entries = <int, ManifestEntry>{};
  for (final id in original.ids) {
    final oldEntry = original[id]!;
    final snapshotBasename = oldEntry.snapshotBasename;
    if (snapshotBasename == null) {
      entries[id] = oldEntry.replaceDwarf(oldEntry.path);
    } else {
      entries[id] = oldEntry
          .replaceDwarf(path.join(outputDir!, snapshotBasename + suffix));
    }
  }
  return Manifest._(entries);
}

const _asmExt = '.S';
const _soExt = '.so';

Future<List<String>> testNonDwarf(String tempDir, String scriptDill) async {
  final scriptNonDwarfUnitManifestPath =
      path.join(tempDir, 'manifest_non_dwarf.json');
  final scriptNonDwarfSnapshot = path.join(tempDir, 'non_dwarf' + _soExt);
  await run(genSnapshot, <String>[
    '--no-dwarf-stack-traces-mode',
    '--loading-unit-manifest=$scriptNonDwarfUnitManifestPath',
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptNonDwarfSnapshot',
    scriptDill,
  ]);

  final scriptNonDwarfUnitManifest =
      Manifest.fromPath(scriptNonDwarfUnitManifestPath);
  if (scriptNonDwarfUnitManifest == null) {
    throw "Failure parsing manifest $scriptNonDwarfUnitManifestPath";
  }
  if (!scriptNonDwarfUnitManifest.contains(rootLoadingUnitId)) {
    throw "Manifest '$scriptNonDwarfUnitManifestPath' "
        "does not contain root unit info";
  }
  Expect.stringEquals(scriptNonDwarfSnapshot,
      scriptNonDwarfUnitManifest[rootLoadingUnitId]!.path);

  // Run the resulting non-Dwarf-AOT compiled script.
  final nonDwarfTrace1 =
      (await original.runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    scriptNonDwarfSnapshot,
  ]))
          .trace;
  final nonDwarfTrace2 =
      (await original.runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    scriptNonDwarfSnapshot,
  ]))
          .trace;

  // Ensure the result is based off the flag passed to gen_snapshot, not
  // the one passed to the runtime.
  Expect.deepEquals(nonDwarfTrace1, nonDwarfTrace2);

  return nonDwarfTrace1;
}

Future<void> testElf(
    String tempDir, String scriptDill, List<String> nonDwarfTrace) async {
  final scriptDwarfUnitManifestPath = path.join(tempDir, 'manifest_elf.json');
  final scriptDwarfSnapshot = path.join(tempDir, 'dwarf' + _soExt);
  final scriptDwarfDebugInfo = path.join(tempDir, 'debug_info' + _soExt);
  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$scriptDwarfDebugInfo',
    '--loading-unit-manifest=$scriptDwarfUnitManifestPath',
    '--snapshot-kind=app-aot-elf',
    '--elf=$scriptDwarfSnapshot',
    scriptDill,
  ]);

  final scriptDwarfUnitManifest =
      Manifest.fromPath(scriptDwarfUnitManifestPath);
  if (scriptDwarfUnitManifest == null) {
    throw "Failure parsing manifest $scriptDwarfUnitManifestPath";
  }
  if (!scriptDwarfUnitManifest.contains(rootLoadingUnitId)) {
    throw "Manifest '$scriptDwarfUnitManifest' "
        "does not contain root unit info";
  }
  Expect.stringEquals(
      scriptDwarfSnapshot, scriptDwarfUnitManifest[rootLoadingUnitId]!.path);

  // Run the resulting Dwarf-AOT compiled script.

  final output1 =
      await original.runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    scriptDwarfSnapshot,
  ]);
  final output2 =
      await original.runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    scriptDwarfSnapshot,
  ]);

  // Check with DWARF from separate debugging information.
  await compareTraces(nonDwarfTrace, output1, output2, scriptDwarfUnitManifest);
  // Check with DWARF in generated snapshot (e.g., replacing the Dwarf paths
  // in the dwarf-stack-traces manifest, which point at the separate
  // debugging information, with the output snapshot paths.)
  final manifest = useSnapshotForDwarfPath(scriptDwarfUnitManifest);
  await compareTraces(nonDwarfTrace, output1, output2, manifest);
}

Future<void> testAssembly(
    String tempDir, String scriptDill, List<String> nonDwarfTrace) async {
  // Currently there are no appropriate buildtools on the simulator trybots as
  // normally they compile to ELF and don't need them for compiling assembly
  // snapshots.
  if (isSimulator || (!Platform.isLinux && !Platform.isMacOS)) return;

  final scriptAssembly = path.join(tempDir, 'dwarf_assembly' + _asmExt);
  final scriptDwarfAssemblyDebugInfo =
      path.join(tempDir, 'dwarf_assembly_info' + _soExt);
  final scriptDwarfAssemblyUnitManifestPath =
      path.join(tempDir, 'manifest_assembly.json');

  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$scriptDwarfAssemblyDebugInfo',
    '--loading-unit-manifest=$scriptDwarfAssemblyUnitManifestPath',
    '--snapshot-kind=app-aot-assembly',
    '--assembly=$scriptAssembly',
    scriptDill,
  ]);

  final scriptDwarfAssemblyUnitManifest =
      Manifest.fromPath(scriptDwarfAssemblyUnitManifestPath);
  if (scriptDwarfAssemblyUnitManifest == null) {
    throw "Failure parsing manifest $scriptDwarfAssemblyUnitManifest";
  }
  if (!scriptDwarfAssemblyUnitManifest.contains(rootLoadingUnitId)) {
    throw "Manifest '$scriptDwarfAssemblyUnitManifest' "
        "does not contain root unit info";
  }
  Expect.stringEquals(
      scriptAssembly, scriptDwarfAssemblyUnitManifest[rootLoadingUnitId]!.path);
  Expect.stringEquals(scriptDwarfAssemblyDebugInfo,
      scriptDwarfAssemblyUnitManifest[rootLoadingUnitId]!.dwarfPath!);

  for (final entry in scriptDwarfAssemblyUnitManifest.entries) {
    Expect.isNotNull(entry.snapshotBasename);
    final outputPath = path.join(tempDir, entry.snapshotBasename!);
    await assembleSnapshot(entry.path, outputPath, debug: true);
  }
  final scriptDwarfAssemblySnapshot = path.join(tempDir,
      scriptDwarfAssemblyUnitManifest[rootLoadingUnitId]!.snapshotBasename!);

  // Run the resulting Dwarf-AOT compiled script.
  final assemblyOutput1 =
      await original.runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    scriptDwarfAssemblySnapshot,
    scriptDill,
  ]);
  final assemblyOutput2 =
      await original.runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    scriptDwarfAssemblySnapshot,
    scriptDill,
  ]);

  // Check with DWARF from separate debugging information.
  await compareTraces(nonDwarfTrace, assemblyOutput1, assemblyOutput2,
      scriptDwarfAssemblyUnitManifest,
      fromAssembly: true);
  // Check with DWARF in assembled snapshot. Note that we get a separate .dSYM
  // bundle on MacOS, so we need to add a '.dSYM' suffix there.
  final manifest = useSnapshotForDwarfPath(scriptDwarfAssemblyUnitManifest,
      outputDir: tempDir, suffix: Platform.isMacOS ? '.dSYM' : '');
  await compareTraces(nonDwarfTrace, assemblyOutput1, assemblyOutput2, manifest,
      fromAssembly: true);

  // Next comes tests for MacOS universal binaries.
  if (!Platform.isMacOS) return;

  // Create empty MachO files (just a header) for each of the possible
  // architectures.
  final emptyFiles = <String, String>{};
  for (final arch in original.machOArchNames.values) {
    // Don't create an empty file for the current architecture.
    if (arch == original.dartNameForCurrentArchitecture) continue;
    final contents = emptyMachOForArchitecture(arch);
    Expect.isNotNull(contents);
    final emptyPath = path.join(tempDir, "empty_$arch.so");
    await File(emptyPath).writeAsBytes(contents!, flush: true);
    emptyFiles[arch] = emptyPath;
  }

  Future<void> testUniversalBinary(
      String binaryPath, List<String> machoFiles) async {
    await run(lipo, <String>[...machoFiles, '-create', '-output', binaryPath]);
    final entries = <int, ManifestEntry>{};
    for (final id in scriptDwarfAssemblyUnitManifest.ids) {
      entries[id] = scriptDwarfAssemblyUnitManifest[id]!;
      if (id == rootLoadingUnitId) {
        entries[id] = entries[id]!.replaceDwarf(binaryPath);
      }
    }
    final manifest = Manifest._(entries);
    await compareTraces(
        nonDwarfTrace, assemblyOutput1, assemblyOutput2, manifest,
        fromAssembly: true);
  }

  final scriptDwarfAssemblyDebugSnapshotFile =
      MachO.handleDSYM(manifest[rootLoadingUnitId]!.dwarfPath!);
  await testUniversalBinary(path.join(tempDir, "ub-single"),
      <String>[scriptDwarfAssemblyDebugSnapshotFile]);
  await testUniversalBinary(path.join(tempDir, "ub-multiple"),
      <String>[...emptyFiles.values, scriptDwarfAssemblyDebugSnapshotFile]);
}

Future<void> compareTraces(
    List<String> nonDwarfTrace,
    original.DwarfTestOutput output1,
    original.DwarfTestOutput output2,
    Manifest manifest,
    {bool fromAssembly = false}) async {
  Expect.isNotNull(manifest[rootLoadingUnitId]);

  final header1 = StackTraceHeader.fromLines(output1.trace);
  print('Header1 = $header1');
  checkHeaderWithUnits(header1, fromAssembly: fromAssembly);
  final header2 = StackTraceHeader.fromLines(output2.trace);
  print('Header2 = $header2');
  checkHeaderWithUnits(header2, fromAssembly: fromAssembly);

  // For DWARF stack traces, we can't guarantee that the stack traces are
  // textually equal on all platforms, but if we retrieve the PC offsets
  // out of the stack trace, those should be equal.
  final tracePCOffsets1 = collectPCOffsetsByUnit(output1.trace);
  print("PCOffsets from trace 1:");
  printByUnit(tracePCOffsets1);
  final tracePCOffsets2 = collectPCOffsetsByUnit(output2.trace);
  print("PCOffsets from trace 2:");
  printByUnit(tracePCOffsets2);

  Expect.deepEquals(tracePCOffsets1, tracePCOffsets2);

  Expect.isNotNull(tracePCOffsets1[rootLoadingUnitId]);
  Expect.isNotEmpty(tracePCOffsets1[rootLoadingUnitId]!);
  final sampleOffset = tracePCOffsets1[rootLoadingUnitId]!.first;

  // Only retrieve the DWARF objects that we need to decode the stack traces.
  final dwarfByUnitId = <int, Dwarf>{};
  for (final id in tracePCOffsets1.keys.toSet()) {
    Expect.isTrue(header2.units!.containsKey(id));
    final dwarfPath = manifest[id]!.dwarfPath;
    Expect.isNotNull(dwarfPath);
    print("Reading dwarf for unit $id from $dwarfPath}");
    final dwarf = Dwarf.fromFile(dwarfPath!);
    Expect.isNotNull(dwarf);
    dwarfByUnitId[id] = dwarf!;
  }
  // The first non-root loading unit is not loaded and so shouldn't appear in
  // the stack trace at all, but the root and second non-root loading units do.
  Expect.isTrue(dwarfByUnitId.containsKey(rootLoadingUnitId));
  Expect.isFalse(dwarfByUnitId.containsKey(rootLoadingUnitId + 1));
  Expect.isTrue(dwarfByUnitId.containsKey(rootLoadingUnitId + 2));
  final rootDwarf = dwarfByUnitId[rootLoadingUnitId]!;

  original.checkRootUnitAssumptions(output1, output2, rootDwarf,
      sampleOffset: sampleOffset, matchingBuildIds: !fromAssembly);

  // The offsets of absolute addresses from their respective DSO base
  // should be the same for both traces.
  final absTrace1 = absoluteAddresses(output1.trace);
  print("Absolute addresses from trace 1:");
  printByUnit(absTrace1, toString: addressString);

  final absTrace2 = absoluteAddresses(output2.trace);
  print("Absolute addresses from trace 2:");
  printByUnit(absTrace2, toString: addressString);

  final dsoBase1 = <int, int>{};
  for (final unit in header1.units!.values) {
    dsoBase1[unit.id] = unit.dsoBase;
  }
  print("DSO bases for trace 1:");
  for (final unitId in dsoBase1.keys) {
    print("  $unitId => 0x${dsoBase1[unitId]!.toRadixString(16)}");
  }

  final dsoBase2 = <int, int>{};
  for (final unit in header2.units!.values) {
    dsoBase2[unit.id] = unit.dsoBase;
  }
  print("DSO bases for trace 2:");
  for (final unitId in dsoBase2.keys) {
    print("  $unitId => 0x${dsoBase2[unitId]!.toRadixString(16)}");
  }

  final relocatedFromDso1 = Map.fromEntries(absTrace1.keys.map((unitId) =>
      MapEntry(unitId, absTrace1[unitId]!.map((a) => a - dsoBase1[unitId]!))));
  print("Relocated addresses from trace 1:");
  printByUnit(relocatedFromDso1, toString: addressString);

  final relocatedFromDso2 = Map.fromEntries(absTrace2.keys.map((unitId) =>
      MapEntry(unitId, absTrace2[unitId]!.map((a) => a - dsoBase2[unitId]!))));
  print("Relocated addresses from trace 2:");
  printByUnit(relocatedFromDso2, toString: addressString);

  Expect.deepEquals(relocatedFromDso1, relocatedFromDso2);

  // We don't print 'virt' relocated addresses when running assembled snapshots.
  if (fromAssembly) return;

  // The relocated addresses marked with 'virt' should match between the
  // different runs, and they should also match the relocated address
  // calculated from the PCOffset for each frame as well as the relocated
  // address for each frame calculated using the respective DSO base.
  //
  // Note that since only addresses in the root loading unit are marked with
  // 'virt', we don't need to handle other loading units here.
  final virtTrace1 = explicitVirtualAddresses(output1.trace);
  print("Virtual addresses in frames from trace 1:");
  printByUnit(virtTrace1, toString: addressString);
  final virtTrace2 = explicitVirtualAddresses(output2.trace);
  print("Virtual addresses in frames from trace 2:");
  printByUnit(virtTrace2, toString: addressString);

  final fromTracePCOffsets1 = <int, Iterable<int>>{};
  for (final unitId in tracePCOffsets1.keys) {
    final dwarf = dwarfByUnitId[unitId];
    Expect.isNotNull(dwarf);
    fromTracePCOffsets1[unitId] =
        tracePCOffsets1[unitId]!.map((o) => o.virtualAddressIn(dwarf!));
  }
  print("Virtual addresses calculated from PCOffsets in trace 1:");
  printByUnit(fromTracePCOffsets1, toString: addressString);
  final fromTracePCOffsets2 = <int, Iterable<int>>{};
  for (final unitId in tracePCOffsets2.keys) {
    final dwarf = dwarfByUnitId[unitId];
    Expect.isNotNull(dwarf);
    fromTracePCOffsets2[unitId] =
        tracePCOffsets2[unitId]!.map((o) => o.virtualAddressIn(dwarf!));
  }
  print("Virtual addresses calculated from PCOffsets in trace 2:");
  printByUnit(fromTracePCOffsets2, toString: addressString);

  Expect.deepEquals(virtTrace1, virtTrace2);
  Expect.deepEquals(virtTrace1, fromTracePCOffsets1);
  Expect.deepEquals(virtTrace2, fromTracePCOffsets2);
  Expect.deepEquals(virtTrace1, relocatedFromDso1);
  Expect.deepEquals(virtTrace2, relocatedFromDso2);

  // Check that translating the DWARF stack trace (without internal frames)
  // matches the symbolic stack trace, and that for ELF outputs, we can also
  // decode using the build IDs instead of a unit ID to unit map.
  final decoder =
      DwarfStackTraceDecoder(rootDwarf, dwarfByUnitId: dwarfByUnitId);
  final translatedDwarfTrace1 =
      await Stream.fromIterable(output1.trace).transform(decoder).toList();
  if (!fromAssembly) {
    final unitDwarfs = dwarfByUnitId.values;
    final decoder2 = DwarfStackTraceDecoder(rootDwarf, unitDwarfs: unitDwarfs);
    final translatedDwarfTrace2 =
        await Stream.fromIterable(output1.trace).transform(decoder2).toList();
    Expect.deepEquals(translatedDwarfTrace1, translatedDwarfTrace2);
  }

  original.checkTranslatedTrace(nonDwarfTrace, translatedDwarfTrace1);
}

void checkHeaderWithUnits(StackTraceHeader header,
    {bool fromAssembly = false}) {
  original.checkHeader(header);
  // Additional requirements for the deferred test.
  Expect.isNotNull(header.units);
  // There should be an entry included for the root loading unit.
  Expect.isNotNull(header.units![rootLoadingUnitId]);
  // The first non-root loading unit is never loaded by the test program.
  // Verify that it is not listed for direct-to-ELF snapshots. (It may be
  // eagerly loaded in assembly snapshots.)
  if (!fromAssembly) {
    Expect.isNull(header.units![rootLoadingUnitId + 1]);
  }
  // There should be an entry included for the second non-root loading unit.
  Expect.isNotNull(header.units![rootLoadingUnitId + 2]);
  for (final unitId in header.units!.keys) {
    final unit = header.units![unitId]!;
    Expect.equals(unitId, unit.id);
    Expect.isNotNull(unit.buildId);
  }
  // The information for the root loading unit should match the non-loading
  // unit information in the header.
  Expect.equals(header.isolateStart!, header.units![rootLoadingUnitId]!.start!);
  Expect.equals(
      header.isolateDsoBase!, header.units![rootLoadingUnitId]!.dsoBase!);
  Expect.stringEquals(
      header.buildId!, header.units![rootLoadingUnitId]!.buildId!);
}

Map<int, Iterable<PCOffset>> collectPCOffsetsByUnit(Iterable<String> lines) {
  final result = <int, List<PCOffset>>{};
  for (final o in collectPCOffsets(lines)) {
    final unitId = o.unitId!;
    result[unitId] ??= <PCOffset>[];
    result[unitId]!.add(o);
  }
  return result;
}

final _unitRE = RegExp(r' unit (\d+)');

// Unlike in the original, we want to also collect addressed based on the
// loading unit.
Map<int, Iterable<int>> parseUsingAddressRegExp(
    RegExp re, Iterable<String> lines) {
  final result = <int, List<int>>{};
  for (final line in lines) {
    var match = re.firstMatch(line);
    if (match != null) {
      final address = int.parse(match.group(1)!, radix: 16);
      var unitId = rootLoadingUnitId;
      match = _unitRE.firstMatch(line);
      if (match != null) {
        unitId = int.parse(match.group(1)!);
      }
      result[unitId] ??= <int>[];
      result[unitId]!.add(address);
    }
  }
  return result;
}

final _absRE = RegExp(r'abs ([a-f\d]+)');

Map<int, Iterable<int>> absoluteAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_absRE, lines);

final _virtRE = RegExp(r'virt ([a-f\d]+)');

Map<int, Iterable<int>> explicitVirtualAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_virtRE, lines);

void printByUnit<X>(Map<int, Iterable<X>> valuesByUnit,
    {String Function(X) toString = objectString}) {
  for (final unitId in valuesByUnit.keys) {
    print("  For unit $unitId:");
    for (final value in valuesByUnit[unitId]!) {
      print("    * ${toString(value)}");
    }
  }
}

String objectString(dynamic object) => object.toString();
String addressString(int address) => address.toRadixString(16);

class ManifestEntry {
  final int id;
  final String path;
  final String? dwarfPath;
  final String? snapshotBasename;

  const ManifestEntry._(this.id, this.path,
      {this.dwarfPath, this.snapshotBasename});

  static const _idKey = "id";
  static const _pathKey = "path";
  static const _dwarfPathKey = "debugPath";

  static ManifestEntry? fromJson(Map<String, dynamic> entry) {
    final int? id = entry[_idKey];
    if (id == null) return null;
    final String? path = entry[_pathKey];
    if (path == null) return null;
    if (!File(path).existsSync()) return null;
    final String? dwarfPath = entry[_dwarfPathKey];
    if (dwarfPath != null) {
      if (!File(dwarfPath).existsSync()) return null;
    }
    return ManifestEntry._(id, path, dwarfPath: dwarfPath);
  }

  ManifestEntry replaceSnapshotBasename(String basename) =>
      ManifestEntry._(id, path,
          dwarfPath: dwarfPath, snapshotBasename: basename);

  ManifestEntry replaceDwarf(String newPath) => ManifestEntry._(id, path,
      dwarfPath: newPath, snapshotBasename: snapshotBasename);
}

class Manifest {
  final Map<int, ManifestEntry> _map;

  const Manifest._(this._map);

  static Manifest? fromJson(Map<String, dynamic> manifestJson) {
    final entriesJson = manifestJson["loadingUnits"];
    if (entriesJson == null) return null;
    final entryMap = <int, ManifestEntry>{};
    for (final entryJson in entriesJson) {
      final entry = ManifestEntry.fromJson(entryJson);
      if (entry == null) return null;
      entryMap[entry.id] = entry;
    }
    final rootEntry = entryMap[rootLoadingUnitId];
    if (rootEntry == null) return null;
    if (rootEntry.path.endsWith(_asmExt)) {
      // Add the expected basenames for the assembled snapshots.
      var basename = path.basename(rootEntry.path);
      basename =
          basename.replaceRange(basename.length - _asmExt.length, null, _soExt);
      entryMap[rootLoadingUnitId] = rootEntry.replaceSnapshotBasename(basename);
      for (final id in entryMap.keys) {
        if (id == rootLoadingUnitId) continue;
        final entry = entryMap[id]!;
        // Note that this must match the suffix added to the snapshot URI
        // in Loader::DeferredLoadHandler.
        entryMap[id] = entryMap[id]!
            .replaceSnapshotBasename(basename + '-$id.part' + _soExt);
      }
    }
    return Manifest._(entryMap);
  }

  static Manifest? fromPath(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    return fromJson(json.decode(file.readAsStringSync()));
  }

  int get length => _map.length;

  bool contains(int i) => _map.containsKey(i);
  ManifestEntry? operator [](int i) => _map[i];

  Iterable<int> get ids => _map.keys;
  Iterable<ManifestEntry> get entries => _map.values;
}
