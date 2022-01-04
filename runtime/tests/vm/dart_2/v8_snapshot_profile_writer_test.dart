// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:path/path.dart' as path;
import 'package:vm_snapshot_analysis/v8_profile.dart';

import 'use_flag_test_helper.dart';

// Used to ensure we don't have multiple equivalent calls to test.
final _seenDescriptions = <String>{};

Snapshot testProfile(String profilePath) {
  final profile =
      Snapshot.fromJson(jsonDecode(File(profilePath).readAsStringSync()));

  // Verify that there are no "unknown" nodes. These are emitted when we see a
  // reference to an some object but no other metadata about the object was
  // recorded. We should at least record the type for every object in the
  // graph (in some cases the shallow size can legitimately be 0, e.g. for
  // "base objects" not written to the snapshot or artificial nodes).
  for (final node in profile.nodes) {
    Expect.notEquals("Unknown", node.type, "unknown node ${node}");
  }

  final root = profile.nodeAt(0);
  final reachable = <Node>{};

  // HeapSnapshotWorker.HeapSnapshot.calculateDistances (from HeapSnapshot.js)
  // assumes that the graph root has at most one edge to any other node
  // (most likely an oversight).
  for (final edge in root.edges) {
    Expect.isTrue(
        reachable.add(edge.target),
        "root\n\n$root\n\nhas multiple edges to node\n\n${edge.target}:\n\n"
        "${root.edges.where((e) => e.target == edge.target).toList()}");
  }

  // Check that all other nodes are reachable from the root.
  final stack = <Node>[...reachable];
  while (!stack.isEmpty) {
    final next = stack.removeLast();
    for (final edge in next.edges) {
      if (reachable.add(edge.target)) {
        stack.add(edge.target);
      }
    }
  }

  final unreachable =
      profile.nodes.skip(1).where((Node n) => !reachable.contains(n)).toSet();
  Expect.isEmpty(unreachable);

  return profile;
}

Future<void> testJIT(String dillPath, String snapshotKind) async {
  final includesCode = snapshotKind == 'core-jit';
  final description = snapshotKind;
  Expect.isTrue(_seenDescriptions.add(description),
      "test configuration $description would be run multiple times");

  await withTempDir('v8-snapshot-profile-$description', (String tempDir) async {
    // Generate the snapshot profile.
    final profilePath = path.join(tempDir, 'profile.heapsnapshot');
    final vmTextPath = path.join(tempDir, 'vm_instructions.bin');
    final isolateTextPath = path.join(tempDir, 'isolate_instructions.bin');
    final vmDataPath = path.join(tempDir, 'vm_data.bin');
    final isolateDataPath = path.join(tempDir, 'isolate_data.bin');

    await run(genSnapshot, <String>[
      '--snapshot-kind=$snapshotKind',
      if (includesCode) ...<String>[
        '--vm_snapshot_instructions=$vmTextPath',
        '--isolate_snapshot_instructions=$isolateTextPath',
      ],
      '--vm_snapshot_data=$vmDataPath',
      '--isolate_snapshot_data=$isolateDataPath',
      "--write-v8-snapshot-profile-to=$profilePath",
      dillPath,
    ]);

    print("Snapshot profile generated at $profilePath.");

    final profile = testProfile(profilePath);

    // Verify that the total size of the snapshot text and data sections is
    // the same as the sum of the shallow sizes of all objects in the profile.
    // This ensures that all bytes are accounted for in some way.
    int actualSize =
        await File(vmDataPath).length() + await File(isolateDataPath).length();
    if (includesCode) {
      actualSize += await File(vmTextPath).length() +
          await File(isolateTextPath).length();
    }
    final expectedSize =
        profile.nodes.fold<int>(0, (size, n) => size + n.selfSize);

    Expect.equals(expectedSize, actualSize, "failed on $description snapshot");
  });
}

Future<void> testAOT(String dillPath,
    {bool useAsm = false,
    bool forceDrops = false,
    bool stripUtil = false, // Note: forced true if useAsm.
    bool stripFlag = false,
    bool disassemble = false}) async {
  if (const bool.fromEnvironment('dart.vm.product') && disassemble) {
    Expect.isFalse(disassemble, 'no use of disassembler in PRODUCT mode');
  }

  // For assembly, we can't test the sizes of the snapshot sections, since we
  // don't have a Mach-O reader for Mac snapshots and for ELF, the assembler
  // merges the text/data sections and the VM/isolate section symbols may not
  // have length information. Thus, we force external stripping so we can test
  // the approximate size of the stripped snapshot.
  if (useAsm) {
    stripUtil = true;
  }

  final descriptionBuilder = StringBuffer()..write(useAsm ? 'assembly' : 'elf');
  if (forceDrops) {
    descriptionBuilder.write('-dropped');
  }
  if (stripFlag) {
    descriptionBuilder.write('-intstrip');
  }
  if (stripUtil) {
    descriptionBuilder.write('-extstrip');
  }
  if (disassemble) {
    descriptionBuilder.write('-disassembled');
  }

  final description = descriptionBuilder.toString();
  Expect.isTrue(_seenDescriptions.add(description),
      "test configuration $description would be run multiple times");

  await withTempDir('v8-snapshot-profile-$description', (String tempDir) async {
    // Generate the snapshot profile.
    final profilePath = path.join(tempDir, 'profile.heapsnapshot');
    final snapshotPath = path.join(tempDir, 'test.snap');
    final commonSnapshotArgs = [
      if (stripFlag) '--strip', //  gen_snapshot specific and not a VM flag.
      "--write-v8-snapshot-profile-to=$profilePath",
      if (forceDrops) ...[
        '--dwarf-stack-traces',
        '--no-retain-function-objects',
        '--no-retain-code-objects'
      ],
      if (disassemble) '--disassemble', // Not defined in PRODUCT mode.
      dillPath,
    ];

    if (useAsm) {
      final assemblyPath = path.join(tempDir, 'test.S');

      await run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-assembly',
        '--assembly=$assemblyPath',
        ...commonSnapshotArgs,
      ]);

      await assembleSnapshot(assemblyPath, snapshotPath);
    } else {
      await run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-elf',
        '--elf=$snapshotPath',
        ...commonSnapshotArgs,
      ]);
    }

    String strippedPath;
    if (stripUtil) {
      strippedPath = snapshotPath + '.stripped';
      await stripSnapshot(snapshotPath, strippedPath, forceElf: !useAsm);
    } else {
      strippedPath = snapshotPath;
    }

    print("Snapshot generated at $snapshotPath.");
    print("Snapshot profile generated at $profilePath.");

    final profile = testProfile(profilePath);

    final expectedSize =
        profile.nodes.fold<int>(0, (size, n) => size + n.selfSize);

    // May not be ELF, but another format.
    final elf = Elf.fromFile(snapshotPath);

    var checkedSize = false;
    if (!useAsm) {
      // Verify that the total size of the snapshot text and data section
      // symbols is the same as the sum of the shallow sizes of all objects in
      // the profile. This ensures that all bytes are accounted for in some way.
      //
      // We only check this when generating ELF directly because that's when
      // we're guaranteed the symbols will have non-zero size.
      Expect.isNotNull(elf);

      final vmTextSectionSymbol = elf.dynamicSymbolFor(vmSymbolName);
      Expect.isNotNull(vmTextSectionSymbol);
      final vmDataSectionSymbol = elf.dynamicSymbolFor(vmDataSymbolName);
      Expect.isNotNull(vmDataSectionSymbol);
      final isolateTextSectionSymbol = elf.dynamicSymbolFor(isolateSymbolName);
      Expect.isNotNull(isolateTextSectionSymbol);
      final isolateDataSectionSymbol =
          elf.dynamicSymbolFor(isolateDataSymbolName);
      Expect.isNotNull(isolateDataSectionSymbol);

      final actualSize = vmTextSectionSymbol.size +
          vmDataSectionSymbol.size +
          isolateTextSectionSymbol.size +
          isolateDataSectionSymbol.size;

      Expect.equals(expectedSize, actualSize,
          "symbol size check failed on $description snapshot");
      checkedSize = true;
    }

    // See Elf::kPages in runtime/vm/elf.h, which is also used for assembly
    // padding.
    final segmentAlignment = 16 * 1024;

    if (elf != null) {
      // Verify that the total size of the snapshot text and data sections is
      // approximately the sum of the shallow sizes of all objects in the
      // profile. As sections might be merged by the assembler when useAsm is
      // true, we need to account for possible padding.
      final textSections = elf.namedSections(".text");
      Expect.isNotEmpty(textSections);
      Expect.isTrue(
          textSections.length <= 2, "More text sections than expected");
      final dataSections = elf.namedSections(".rodata");
      Expect.isNotEmpty(dataSections);
      Expect.isTrue(
          dataSections.length <= 2, "More data sections than expected");

      var actualSize = 0;
      for (final section in textSections) {
        actualSize += section.length;
      }
      for (final section in dataSections) {
        actualSize += section.length;
      }

      final mergedCount = (2 - textSections.length) + (2 - dataSections.length);
      final possiblePadding = mergedCount * segmentAlignment;

      Expect.approxEquals(
          expectedSize,
          actualSize,
          possiblePadding,
          "section size failed on $description snapshot" +
              (!useAsm ? ", but symbol size test passed" : ""));
      checkedSize = true;
    }

    if (stripUtil || stripFlag) {
      // Verify that the actual size of the stripped snapshot is close to the
      // sum of the shallow sizes of all objects in the profile. They will not
      // be exactly equal because of global headers, padding, and non-text/data
      // sections.
      var strippedSnapshotPath = snapshotPath;
      if (stripUtil) {
        strippedSnapshotPath = snapshotPath + '.stripped';
        await stripSnapshot(snapshotPath, strippedSnapshotPath,
            forceElf: !useAsm);
        print("Stripped snapshot generated at $strippedSnapshotPath.");
      }

      final actualSize = await File(strippedSnapshotPath).length();

      // Not every byte is accounted for by the snapshot profile, and data and
      // instruction segments are padded to an alignment boundary.
      final tolerance = 0.04 * actualSize + 2 * segmentAlignment;

      Expect.approxEquals(
          expectedSize,
          actualSize,
          tolerance,
          "total size check failed on $description snapshot" +
              (elf != null ? ", but section size checks passed" : ""));
      checkedSize = true;
    }

    Expect.isTrue(checkedSize, "no snapshot size checks were performed");
  });
}

Match matchComplete(RegExp regexp, String line) {
  Match match = regexp.firstMatch(line);
  if (match == null) return match;
  if (match.start != 0 || match.end != line.length) return null;
  return match;
}

// All fields of "Raw..." classes defined in "raw_object.h" must be included in
// the giant macro in "raw_object_fields.cc". This function attempts to check
// that with some basic regexes.
testMacros() async {
  const String className = "([a-z0-9A-Z]+)";
  const String rawClass = "Raw$className";
  const String fieldName = "([a-z0-9A-Z_]+)";

  final Map<String, Set<String>> fields = {};

  final String rawObjectFieldsPath =
      path.join(sdkDir, 'runtime', 'vm', 'raw_object_fields.cc');
  final RegExp fieldEntry = RegExp(" *F\\($className, $fieldName\\) *\\\\?");

  await for (String line in File(rawObjectFieldsPath)
      .openRead()
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(LineSplitter())) {
    Match match = matchComplete(fieldEntry, line);
    if (match != null) {
      fields
          .putIfAbsent(match.group(1), () => Set<String>())
          .add(match.group(2));
    }
  }

  final RegExp classStart = RegExp("class $rawClass : public $rawClass {");
  final RegExp classEnd = RegExp("}");
  final RegExp field = RegExp("  $rawClass. +$fieldName;.*");

  final String rawObjectPath =
      path.join(sdkDir, 'runtime', 'vm', 'raw_object.h');

  String currentClass;
  bool hasMissingFields = false;
  await for (String line in File(rawObjectPath)
      .openRead()
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(LineSplitter())) {
    Match match = matchComplete(classStart, line);
    if (match != null) {
      currentClass = match.group(1);
      continue;
    }

    match = matchComplete(classEnd, line);
    if (match != null) {
      currentClass = null;
      continue;
    }

    match = matchComplete(field, line);
    if (match != null && currentClass != null) {
      if (fields[currentClass] == null) {
        hasMissingFields = true;
        print("$currentClass is missing entirely.");
        continue;
      }
      if (!fields[currentClass].contains(match.group(2))) {
        hasMissingFields = true;
        print("$currentClass is missing ${match.group(2)}.");
      }
    }
  }

  if (hasMissingFields) {
    Expect.fail("$rawObjectFieldsPath is missing some fields. "
        "Please update it to match $rawObjectPath.");
  }
}

main() async {
  void printSkip(String description) =>
      print('Skipping $description for ${path.basename(buildDir)} '
              'on ${Platform.operatingSystem}' +
          (clangBuildToolsDir == null ? ' without //buildtools' : ''));

  // We don't have access to the SDK on Android.
  if (Platform.isAndroid) {
    printSkip('all tests');
    return;
  }

  await testMacros();

  await withTempDir('v8-snapshot-profile-writer', (String tempDir) async {
    // We only need to generate the dill file once for all JIT tests.
    final _thisTestPath = path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
        'v8_snapshot_profile_writer_test.dart');
    final jitDillPath = path.join(tempDir, 'jit_test.dill');
    await run(genKernel,
        <String>['--platform', platformDill, '-o', jitDillPath, _thisTestPath]);

    // We only need to generate the dill file once for all AOT tests.
    final aotDillPath = path.join(tempDir, 'aot_test.dill');
    await run(genKernel, <String>[
      '--aot',
      '--platform',
      platformDill,
      '-o',
      aotDillPath,
      _thisTestPath
    ]);

    // Just as a reminder for AOT tests:
    // * If useAsm is true, then stripUtil is forced (as the assembler may add
    //   extra information that needs stripping), so no need to specify
    //   stripUtil for useAsm tests.

    // Test profile generation with a core snapshot (no code).
    await testJIT(jitDillPath, 'core');
    // Test profile generation with a core JIT snapshot (with code).
    await testJIT(jitDillPath, 'core-jit');

    // Test unstripped ELF generation directly.
    await testAOT(aotDillPath);
    await testAOT(aotDillPath, forceDrops: true);

    // Test flag-stripped ELF generation.
    await testAOT(aotDillPath, stripFlag: true);

    // We neither generate assembly nor have a stripping utility on Windows.
    if (Platform.isWindows) {
      printSkip('external stripping and assembly tests');
      return;
    }

    // The native strip utility on Mac OS X doesn't recognize ELF files.
    if (Platform.isMacOS && clangBuildToolsDir == null) {
      printSkip('ELF external stripping test');
    } else {
      // Test unstripped ELF generation that is then externally stripped.
      await testAOT(aotDillPath, stripUtil: true);
    }

    // TODO(sstrickl): Currently we can't assemble for SIMARM64 on MacOSX.
    // For example, the test runner still uses blobs for
    // dartkp-mac-*-simarm64. Change assembleSnapshot and remove this check
    // when we can.
    if (Platform.isMacOS && buildDir.endsWith('SIMARM64')) {
      printSkip('assembly tests');
      return;
    }
    // Test unstripped assembly generation that is then externally stripped.
    await testAOT(aotDillPath, useAsm: true);
    // Test stripped assembly generation that is then externally stripped.
    await testAOT(aotDillPath, useAsm: true, stripFlag: true);
  });
}
