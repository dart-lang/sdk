// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'package:vm_snapshot_analysis/v8_profile.dart';

import 'use_flag_test_helper.dart';

test(
    {String dillPath,
    bool useAsm,
    bool useBare,
    bool stripFlag,
    bool stripUtil,
    bool disassemble = false}) async {
  // We don't assume forced disassembler support in Product mode, so skip any
  // disassembly test.
  if (!const bool.fromEnvironment('dart.vm.product') && disassemble) return;

  // The assembler may add extra unnecessary information to the compiled
  // snapshot whether or not we generate DWARF information in the assembly, so
  // we force the use of a utility when generating assembly.
  if (useAsm) Expect.isTrue(stripUtil);

  // We must strip the output in some way when generating ELF snapshots,
  // else the debugging information added will cause the test to fail.
  if (!stripUtil) Expect.isTrue(stripFlag);

  final tempDirPrefix = 'v8-snapshot-profile' +
      (useAsm ? '-assembly' : '-elf') +
      (useBare ? '-bare' : '-nonbare') +
      (stripFlag ? '-intstrip' : '') +
      (stripUtil ? '-extstrip' : '') +
      (disassemble ? '-disassembled' : '');

  await withTempDir(tempDirPrefix, (String tempDir) async {
    // Generate the snapshot profile.
    final profilePath = path.join(tempDir, 'profile.heapsnapshot');
    final snapshotPath = path.join(tempDir, 'test.snap');
    final commonSnapshotArgs = [
      if (stripFlag) '--strip',
      useBare ? '--use-bare-instructions' : '--no-use-bare-instructions',
      "--write-v8-snapshot-profile-to=$profilePath",
      if (disassemble) '--disassemble',
      '--ignore-unrecognized-flags',
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

    final profile =
        Snapshot.fromJson(jsonDecode(File(profilePath).readAsStringSync()));

    // Verify that there are no "unknown" nodes. These are emitted when we see a
    // reference to an some object but no other metadata about the object was
    // recorded. We should at least record the type for every object in the
    // graph (in some cases the shallow size can legitimately be 0, e.g. for
    // "base objects").
    for (final node in profile.nodes) {
      Expect.notEquals("Unknown", node.type, "unknown node at ID ${node.id}");
    }

    // HeapSnapshotWorker.HeapSnapshot.calculateDistances (from HeapSnapshot.js)
    // assumes that the root does not have more than one edge to any other node
    // (most likely an oversight).
    final Set<int> roots = <int>{};
    for (final edge in profile.nodeAt(0).edges) {
      Expect.isTrue(roots.add(edge.target.index));
    }

    // Check that all nodes are reachable from the root (index 0).
    final Set<int> reachable = {0};
    final dfs = <int>[0];
    while (!dfs.isEmpty) {
      final next = dfs.removeLast();
      for (final edge in profile.nodeAt(next).edges) {
        final target = edge.target;
        if (!reachable.contains(target.index)) {
          reachable.add(target.index);
          dfs.add(target.index);
        }
      }
    }

    if (reachable.length != profile.nodeCount) {
      for (final node in profile.nodes) {
        Expect.isTrue(reachable.contains(node.index),
            "unreachable node at ID ${node.id}");
      }
    }

    // Verify that the actual size of the snapshot is close to the sum of the
    // shallow sizes of all objects in the profile. They will not be exactly
    // equal because of global headers and padding.
    final actual = await File(strippedPath).length();
    final expected = profile.nodes.fold<int>(0, (size, n) => size + n.selfSize);

    final bareUsed = useBare ? "bare" : "non-bare";
    final fileType = useAsm ? "assembly" : "ELF";
    String stripPrefix = "";
    if (stripFlag && stripUtil) {
      stripPrefix = "internally and externally stripped ";
    } else if (stripFlag) {
      stripPrefix = "internally stripped ";
    } else if (stripUtil) {
      stripPrefix = "externally stripped ";
    }

    Expect.approxEquals(expected, actual, 0.03 * actual,
        "failed on $bareUsed $stripPrefix$fileType snapshot type.");
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
    // We only need to generate the dill file once.
    final _thisTestPath = path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart_2',
        'v8_snapshot_profile_writer_test.dart');
    final dillPath = path.join(tempDir, 'test.dill');
    await run(genKernel, <String>[
      '--aot',
      '--platform',
      platformDill,
      '-o',
      dillPath,
      _thisTestPath
    ]);

    // Test stripped ELF generation directly.
    await test(
        dillPath: dillPath,
        stripFlag: true,
        stripUtil: false,
        useAsm: false,
        useBare: false);
    await test(
        dillPath: dillPath,
        stripFlag: true,
        stripUtil: false,
        useAsm: false,
        useBare: true);

    // Regression test for dartbug.com/41149.
    await test(
        dillPath: dillPath,
        stripFlag: true,
        stripUtil: false,
        useAsm: false,
        useBare: false,
        disassemble: true);

    // We neither generate assembly nor have a stripping utility on Windows.
    if (Platform.isWindows) {
      printSkip('external stripping and assembly tests');
      return;
    }

    // The native strip utility on Mac OS X doesn't recognize ELF files.
    if (Platform.isMacOS && clangBuildToolsDir == null) {
      printSkip('ELF external stripping test');
    } else {
      // Test unstripped ELF generation that is then stripped externally.
      await test(
          dillPath: dillPath,
          stripFlag: false,
          stripUtil: true,
          useAsm: false,
          useBare: false);
      await test(
          dillPath: dillPath,
          stripFlag: false,
          stripUtil: true,
          useAsm: false,
          useBare: true);
    }

    // TODO(sstrickl): Currently we can't assemble for SIMARM64 on MacOSX.
    // For example, the test runner still uses blobs for dartkp-mac-*-simarm64.
    // Change assembleSnapshot and remove this check when we can.
    if (Platform.isMacOS && buildDir.endsWith('SIMARM64')) {
      printSkip('assembly tests');
      return;
    }

    // Test stripped assembly generation that is then compiled and stripped.
    await test(
        dillPath: dillPath,
        stripFlag: true,
        stripUtil: true,
        useAsm: true,
        useBare: false);
    await test(
        dillPath: dillPath,
        stripFlag: true,
        stripUtil: true,
        useAsm: true,
        useBare: true);
    // Test unstripped assembly generation that is then compiled and stripped.
    await test(
        dillPath: dillPath,
        stripFlag: false,
        stripUtil: true,
        useAsm: true,
        useBare: false);
    await test(
        dillPath: dillPath,
        stripFlag: false,
        stripUtil: true,
        useAsm: true,
        useBare: true);
  });
}
