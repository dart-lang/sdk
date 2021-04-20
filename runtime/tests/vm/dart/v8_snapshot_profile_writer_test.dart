// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'package:vm_snapshot_analysis/v8_profile.dart';

import 'use_flag_test_helper.dart';

// Used to ensure we don't have multiple equivalent calls to test.
final _seenDescriptions = <String>{};

Future<void> test(String dillPath,
    {bool useAsm = false,
    bool useBare = true,
    bool forceDrops = false,
    bool useDispatch = true,
    bool stripUtil = false, // Note: forced if useAsm.
    bool stripFlag = false, // Note: forced if !stripUtil (and thus !useAsm).
    bool disassemble = false}) async {
  // We don't assume forced disassembler support in Product mode, so skip any
  // disassembly test.
  if (!const bool.fromEnvironment('dart.vm.product') && disassemble) {
    return;
  }

  // The assembler may add extra unnecessary information to the compiled
  // snapshot whether or not we generate DWARF information in the assembly, so
  // we force the use of a utility when generating assembly.
  if (useAsm) {
    stripUtil = true;
  }

  // We must strip the output in some way when generating ELF snapshots,
  // else the debugging information added will cause the test to fail.
  if (!stripUtil) {
    stripFlag = true;
  }

  final descriptionBuilder = StringBuffer()..write(useAsm ? 'assembly' : 'elf');
  if (!useBare) {
    descriptionBuilder.write('-nonbare');
  }
  if (forceDrops) {
    descriptionBuilder.write('-dropped');
  }
  if (!useDispatch) {
    descriptionBuilder.write('-nodispatch');
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
      if (stripFlag) '--strip',
      useBare ? '--use-bare-instructions' : '--no-use-bare-instructions',
      "--write-v8-snapshot-profile-to=$profilePath",
      if (forceDrops) ...[
        '--dwarf-stack-traces',
        '--no-retain-function-objects',
        '--no-retain-code-objects'
      ],
      if (!useDispatch) '--no-use-table-dispatch',
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

    print("Snapshot profile generated at $profilePath.");

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

    // Verify that the actual size of the snapshot is close to the sum of the
    // shallow sizes of all objects in the profile. They will not be exactly
    // equal because of global headers and padding.
    final actual = await File(strippedPath).length();
    final expected = profile.nodes.fold<int>(0, (size, n) => size + n.selfSize);

    // See Elf::kPages in runtime/vm/elf.h.
    final segmentAlignment = 16 * 1024;
    // Not every byte is accounted for by the snapshot profile, and data and
    // instruction segments are padded to an alignment boundary.
    final tolerance = 0.03 * actual + 2 * segmentAlignment;

    Expect.approxEquals(
        expected, actual, tolerance, "failed on $description snapshot");
  });
}

Match? matchComplete(RegExp regexp, String line) {
  Match? match = regexp.firstMatch(line);
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
    Match? match = matchComplete(fieldEntry, line);
    if (match != null) {
      fields
          .putIfAbsent(match.group(1)!, () => Set<String>())
          .add(match.group(2)!);
    }
  }

  final RegExp classStart = RegExp("class $rawClass : public $rawClass {");
  final RegExp classEnd = RegExp("}");
  final RegExp field = RegExp("  $rawClass. +$fieldName;.*");

  final String rawObjectPath =
      path.join(sdkDir, 'runtime', 'vm', 'raw_object.h');

  String? currentClass;
  bool hasMissingFields = false;
  await for (String line in File(rawObjectPath)
      .openRead()
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(LineSplitter())) {
    Match? match = matchComplete(classStart, line);
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
      if (!fields[currentClass]!.contains(match.group(2)!)) {
        hasMissingFields = true;
        print("$currentClass is missing ${match.group(2)!}.");
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
    final _thisTestPath = path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
        'v8_snapshot_profile_writer_test.dart');
    final dillPath = path.join(tempDir, 'test.dill');
    await run(genKernel, <String>[
      '--aot',
      '--platform',
      platformDill,
      ...Platform.executableArguments.where((arg) =>
          arg.startsWith('--enable-experiment=') ||
          arg == '--sound-null-safety' ||
          arg == '--no-sound-null-safety'),
      '-o',
      dillPath,
      _thisTestPath
    ]);

    // Just as a reminder (these rules are applied in order inside test):
    // If useAsm is true, then stripUtil is forced (as the assembler may add
    // extra information that needs stripping).
    // If stripUtil is false, then stripFlag is forced (as the output must be
    // stripped in some way to remove DWARF information).

    // Test stripped ELF generation directly.
    await test(dillPath);
    await test(dillPath, useBare: false);
    await test(dillPath, forceDrops: true);
    await test(dillPath, forceDrops: true, useBare: false);
    await test(dillPath, forceDrops: true, useDispatch: false);
    await test(dillPath, forceDrops: true, useDispatch: false, useBare: false);

    // Regression test for dartbug.com/41149.
    await test(dillPath, useBare: false, disassemble: true);

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
      await test(dillPath, stripUtil: true);
      await test(dillPath, stripUtil: true, useBare: false);
    }

    // TODO(sstrickl): Currently we can't assemble for SIMARM64 on MacOSX.
    // For example, the test runner still uses blobs for dartkp-mac-*-simarm64.
    // Change assembleSnapshot and remove this check when we can.
    if (Platform.isMacOS && buildDir.endsWith('SIMARM64')) {
      printSkip('assembly tests');
      return;
    }

    // Test unstripped assembly generation that is then compiled and stripped.
    await test(dillPath, useAsm: true);
    await test(dillPath, useAsm: true, useBare: false);
    // Test stripped assembly generation that is then compiled and stripped.
    await test(dillPath, useAsm: true, stripFlag: true);
    await test(dillPath, useAsm: true, stripFlag: true, useBare: false);
  });
}
