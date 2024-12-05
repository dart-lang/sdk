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

import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:native_stack_traces/src/constants.dart' show rootLoadingUnitId;
import 'package:native_stack_traces/src/macho.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'use_flag_test_helper.dart';
import 'use_dwarf_stack_traces_flag_helper.dart';

Future<void> main() async {
  await runTests(
      'dwarf-flag-deferred-test',
      path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
          'use_dwarf_stack_traces_flag_deferred_program.dart'),
      runNonDwarf,
      runElf,
      runAssembly);
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

Future<NonDwarfState> runNonDwarf(String tempDir, String scriptDill) async {
  final manifestPath = path.join(tempDir, 'manifest_non_dwarf.json');
  final snapshotPath = path.join(tempDir, 'non_dwarf' + _soExt);
  await run(genSnapshot, <String>[
    '--no-dwarf-stack-traces-mode',
    '--loading-unit-manifest=$manifestPath',
    '--snapshot-kind=app-aot-elf',
    '--elf=$snapshotPath',
    scriptDill,
  ]);

  final manifest = Manifest.fromPath(manifestPath);
  if (manifest == null) {
    throw "Failure parsing manifest $manifestPath";
  }
  if (!manifest.contains(rootLoadingUnitId)) {
    throw "Manifest '$manifestPath' does not contain root unit info";
  }
  if (snapshotPath != manifest[rootLoadingUnitId]!.path) {
    throw "Manifest '$manifestPath' does not contain expected "
        "root unit path '$snapshotPath'";
  }

  // Run the resulting non-Dwarf-AOT compiled script.
  final outputWithOppositeFlag =
      (await runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    snapshotPath,
  ]));
  final output = (await runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    snapshotPath,
  ]));

  return NonDwarfState(output, outputWithOppositeFlag);
}

/// Maps the id of a loading unit to the DWARF information for the unit.
typedef DwarfMap = Map<int, Dwarf>;

class DeferredElfState extends ElfState<DwarfMap> {
  DeferredElfState(super.snapshot, super.debugInfo, super.output,
      super.outputWithOppositeFlag);

  @override
  Future<void> check(Trace trace, DwarfMap dwarfMap) =>
      compareTraces(trace, output, outputWithOppositeFlag, dwarfMap);
}

Future<DeferredElfState> runElf(String tempDir, String scriptDill) async {
  final manifestPath = path.join(tempDir, 'manifest_elf.json');
  final snapshotPath = path.join(tempDir, 'dwarf' + _soExt);
  final debugInfoPath = path.join(tempDir, 'debug_info' + _soExt);
  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$debugInfoPath',
    '--loading-unit-manifest=$manifestPath',
    '--snapshot-kind=app-aot-elf',
    '--elf=$snapshotPath',
    scriptDill,
  ]);

  final pathManifest = Manifest.fromPath(manifestPath);
  if (pathManifest == null) {
    throw "Failure parsing manifest $manifestPath";
  }
  if (!pathManifest.contains(rootLoadingUnitId)) {
    throw "Manifest '$manifestPath' does not contain root unit info";
  }
  if (snapshotPath != pathManifest[rootLoadingUnitId]!.path) {
    throw "Manifest '$manifestPath' does not contain expected "
        "root unit path '$snapshotPath'";
  }
  if (debugInfoPath != pathManifest[rootLoadingUnitId]!.dwarfPath) {
    throw "Manifest '$manifestPath' does not contain expected "
        "root unit debugging info path '$debugInfoPath'";
  }

  // Run the resulting Dwarf-AOT compiled script.

  final output = await runTestProgram(dartPrecompiledRuntime, <String>[
    '--dwarf-stack-traces-mode',
    snapshotPath,
  ]);
  final outputWithOppositeFlag =
      await runTestProgram(dartPrecompiledRuntime, <String>[
    '--no-dwarf-stack-traces-mode',
    snapshotPath,
  ]);

  final debugInfoDwarfMap = pathManifest.dwarfMap;
  final snapshotDwarfMap = useSnapshotForDwarfPath(pathManifest).dwarfMap;

  return DeferredElfState(
      snapshotDwarfMap, debugInfoDwarfMap, output, outputWithOppositeFlag);
}

class DeferredAssemblyState extends AssemblyState<DwarfMap> {
  DeferredAssemblyState(super.snapshot, super.debugInfo, super.output,
      super.outputWithOppositeFlag,
      [super.singleArch, super.multiArch]);

  @override
  Future<void> check(Trace trace, DwarfMap dwarfMap) =>
      compareTraces(trace, output, outputWithOppositeFlag, dwarfMap,
          fromAssembly: true);
}

Future<DeferredAssemblyState?> runAssembly(
    String tempDir, String scriptDill) async {
  if (skipAssembly != false) return null;

  final assemblyPath = path.join(tempDir, 'dwarf_assembly' + _asmExt);
  final debugInfoPath = path.join(tempDir, 'dwarf_assembly_info' + _soExt);
  final manifestPath = path.join(tempDir, 'manifest_assembly.json');

  await run(genSnapshot, <String>[
    // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
    // the latter is a handler that sets the former and also may change
    // other flags. This way, we limit the difference between the two
    // snapshots and also directly test the flag saved as a VM global flag.
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$debugInfoPath',
    '--loading-unit-manifest=$manifestPath',
    '--snapshot-kind=app-aot-assembly',
    '--assembly=$assemblyPath',
    scriptDill,
  ]);

  final manifest = Manifest.fromPath(manifestPath);
  if (manifest == null) {
    throw "Failure parsing manifest $manifestPath";
  }
  if (!manifest.contains(rootLoadingUnitId)) {
    throw "Manifest '$manifestPath' does not contain root unit info";
  }
  if (assemblyPath != manifest[rootLoadingUnitId]!.path) {
    throw "Manifest '$manifestPath' does not contain expected "
        "root unit path '$assemblyPath'";
  }
  if (debugInfoPath != manifest[rootLoadingUnitId]!.dwarfPath) {
    throw "Manifest '$manifestPath' does not contain expected "
        "root unit debugging info path '$debugInfoPath'";
  }

  for (final entry in manifest.entries) {
    final outputPath = path.join(tempDir, entry.snapshotBasename!);
    await assembleSnapshot(entry.path, outputPath, debug: true);
  }
  final snapshotPath =
      path.join(tempDir, manifest[rootLoadingUnitId]!.snapshotBasename!);

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

  final debugInfoDwarfMap = manifest.dwarfMap;
  final debugManifest = useSnapshotForDwarfPath(manifest,
      outputDir: tempDir, suffix: Platform.isMacOS ? '.dSYM' : '');
  final snapshotDwarfMap = debugManifest.dwarfMap;

  DwarfMap? singleArchSnapshotDwarfMap;
  DwarfMap? multiArchSnapshotDwarfMap;
  if (skipUniversalBinary == false) {
    // Create empty MachO files (just a header) for each of the possible
    // architectures.
    final emptyFiles = <String, String>{};
    for (final arch in machOArchNames.values) {
      // Don't create an empty file for the current architecture.
      if (arch == dartNameForCurrentArchitecture) continue;
      final contents = emptyMachOForArchitecture(arch);
      final emptyPath = path.join(tempDir, "empty_$arch.so");
      await File(emptyPath).writeAsBytes(contents!, flush: true);
      emptyFiles[arch] = emptyPath;
    }

    final singleDir = await Directory(path.join(tempDir, 'ub-single')).create();
    final multiDir = await Directory(path.join(tempDir, 'ub-multi')).create();
    var singleManifest = Manifest.of(debugManifest);
    var multiManifest = Manifest.of(debugManifest);
    for (final id in debugManifest.ids) {
      final entry = debugManifest[id]!;
      final snapshotPath = MachO.handleDSYM(debugManifest[id]!.dwarfPath!);
      final singlePath = path.join(singleDir.path, path.basename(snapshotPath));
      await run(lipo, <String>[snapshotPath, '-create', '-output', singlePath]);
      final multiPath = path.join(multiDir.path, path.basename(snapshotPath));
      await run(lipo, <String>[
        ...emptyFiles.values,
        snapshotPath,
        '-create',
        '-output',
        multiPath
      ]);
      singleManifest[id] = entry.replaceDwarf(singlePath);
      multiManifest[id] = entry.replaceDwarf(multiPath);
    }

    singleArchSnapshotDwarfMap = await singleManifest.dwarfMap;
    multiArchSnapshotDwarfMap = await multiManifest.dwarfMap;
  }

  return DeferredAssemblyState(
      snapshotDwarfMap,
      debugInfoDwarfMap,
      output,
      outputWithOppositeFlag,
      singleArchSnapshotDwarfMap,
      multiArchSnapshotDwarfMap);
}

Future<void> compareTraces(List<String> nonDwarfTrace, DwarfTestOutput output1,
    DwarfTestOutput output2, DwarfMap dwarfMap,
    {bool fromAssembly = false}) async {
  expect(dwarfMap, contains(rootLoadingUnitId));

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

  expect(tracePCOffsets2, equals(tracePCOffsets1));
  expect(tracePCOffsets1, contains(rootLoadingUnitId));
  expect(tracePCOffsets1[rootLoadingUnitId]!, isNotEmpty);
  final sampleOffset = tracePCOffsets1[rootLoadingUnitId]!.first;

  // Only retrieve the DWARF objects that we need to decode the stack traces.
  final dwarfByUnitId = <int, Dwarf>{};
  for (final id in tracePCOffsets1.keys.toSet()) {
    expect(header2.units!, contains(id));
    expect(dwarfMap, contains(id));
    dwarfByUnitId[id] = dwarfMap[id]!;
  }
  // The first non-root loading unit is not loaded and so shouldn't appear in
  // the stack trace at all, but the root and second non-root loading units do.
  expect(dwarfByUnitId, contains(rootLoadingUnitId));
  expect(dwarfByUnitId[rootLoadingUnitId + 1], isNull);
  expect(dwarfByUnitId, contains(rootLoadingUnitId + 2));
  final rootDwarf = dwarfByUnitId[rootLoadingUnitId]!;

  checkRootUnitAssumptions(output1, output2, rootDwarf,
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
  printByUnit(dsoBase1.map((id, dso) => MapEntry(id, <int>[dso])),
      toString: addressString);

  final dsoBase2 = <int, int>{};
  for (final unit in header2.units!.values) {
    dsoBase2[unit.id] = unit.dsoBase;
  }
  print("DSO bases for trace 2:");
  printByUnit(dsoBase2.map((id, dso) => MapEntry(id, <int>[dso])),
      toString: addressString);

  final relocatedFromDso1 = Map.fromEntries(absTrace1.keys.map((unitId) =>
      MapEntry(unitId, absTrace1[unitId]!.map((a) => a - dsoBase1[unitId]!))));
  print("Relocated addresses from trace 1:");
  printByUnit(relocatedFromDso1, toString: addressString);

  final relocatedFromDso2 = Map.fromEntries(absTrace2.keys.map((unitId) =>
      MapEntry(unitId, absTrace2[unitId]!.map((a) => a - dsoBase2[unitId]!))));
  print("Relocated addresses from trace 2:");
  printByUnit(relocatedFromDso2, toString: addressString);

  expect(relocatedFromDso2, equals(relocatedFromDso1));

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
    expect(dwarfByUnitId, contains(unitId));
    final dwarf = dwarfByUnitId[unitId]!;
    fromTracePCOffsets1[unitId] =
        tracePCOffsets1[unitId]!.map((o) => o.virtualAddressIn(dwarf));
  }
  print("Virtual addresses calculated from PCOffsets in trace 1:");
  printByUnit(fromTracePCOffsets1, toString: addressString);
  final fromTracePCOffsets2 = <int, Iterable<int>>{};
  for (final unitId in tracePCOffsets2.keys) {
    expect(dwarfByUnitId, contains(unitId));
    final dwarf = dwarfByUnitId[unitId]!;
    fromTracePCOffsets2[unitId] =
        tracePCOffsets2[unitId]!.map((o) => o.virtualAddressIn(dwarf));
  }
  print("Virtual addresses calculated from PCOffsets in trace 2:");
  printByUnit(fromTracePCOffsets2, toString: addressString);

  expect(virtTrace2, equals(virtTrace1));
  expect(fromTracePCOffsets1, equals(virtTrace1));
  expect(fromTracePCOffsets2, equals(virtTrace2));
  expect(relocatedFromDso1, equals(virtTrace1));
  expect(relocatedFromDso2, equals(virtTrace2));

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
    expect(translatedDwarfTrace2, equals(translatedDwarfTrace1));
  }

  checkTranslatedTrace(nonDwarfTrace, translatedDwarfTrace1);
}

void checkHeaderWithUnits(StackTraceHeader header,
    {bool fromAssembly = false}) {
  checkHeader(header);
  // Additional requirements for the deferred test.
  expect(header.units, isNotNull);
  // There should be an entry included for the root loading unit.
  expect(header.units!, contains(rootLoadingUnitId));
  // The first non-root loading unit is never loaded by the test program.
  // Verify that it is not listed for direct-to-ELF snapshots. (It may be
  // eagerly loaded in assembly snapshots.)
  if (!fromAssembly) {
    expect(header.units![rootLoadingUnitId + 1], isNull);
  }
  // There should be an entry included for the second non-root loading unit.
  expect(header.units!, contains(rootLoadingUnitId + 2));
  for (final unitId in header.units!.keys) {
    final unit = header.units![unitId]!;
    expect(unit.id, equals(unitId));
    expect(unit.buildId, isNotNull);
  }
  // The information for the root loading unit should match the non-loading
  // unit information in the header.
  expect(header.units![rootLoadingUnitId]!.start, equals(header.isolateStart!));
  expect(header.units![rootLoadingUnitId]!.dsoBase,
      equals(header.isolateDsoBase!));
  expect(header.units![rootLoadingUnitId]!.buildId!, equals(header.buildId!));
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
  final buffer = StringBuffer();
  for (final unitId in valuesByUnit.keys) {
    buffer.writeln("  For unit $unitId:");
    for (final value in valuesByUnit[unitId]!) {
      buffer.writeln("    * ${toString(value)}");
    }
  }
  print(buffer.toString());
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

  static Manifest of(Manifest original) => Manifest._(Map.of(original._map));

  DwarfMap get dwarfMap {
    final map = <int, Dwarf>{};
    for (final id in ids) {
      final path = _map[id]!.dwarfPath;
      if (path == null) continue;
      final dwarf = Dwarf.fromFile(path);
      if (dwarf == null) continue;
      map[id] = dwarf;
    }
    return map;
  }

  int get length => _map.length;

  bool contains(int i) => _map.containsKey(i);
  ManifestEntry? operator [](int i) => _map[i];
  void operator []=(int i, ManifestEntry e) => _map[i] = e;

  Iterable<int> get ids => _map.keys;
  Iterable<ManifestEntry> get entries => _map.values;
}
