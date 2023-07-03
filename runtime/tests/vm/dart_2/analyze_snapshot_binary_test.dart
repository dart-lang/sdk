// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

// Used to ensure we don't have multiple equivalent calls to test.
final _seenDescriptions = <String>{};

Future<void> testAOT(String dillPath,
    {bool useAsm = false,
    bool forceDrops = false,
    bool stripUtil = false, // Note: forced true if useAsm.
    bool stripFlag = false,
    bool disassemble = false}) async {
  if (const bool.fromEnvironment('dart.vm.product') && disassemble) {
    Expect.isFalse(disassemble, 'no use of disassembler in PRODUCT mode');
  }

  final analyzeSnapshot = path.join(buildDir, 'analyze_snapshot');

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

  await withTempDir('analyze_snapshot_binary-$description',
      (String tempDir) async {
    // Generate the snapshot
    final snapshotPath = path.join(tempDir, 'test.snap');
    final commonSnapshotArgs = [
      if (stripFlag) '--strip', //  gen_snapshot specific and not a VM flag.
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
        '--no-sound-null-safety',
        '--snapshot-kind=app-aot-assembly',
        '--assembly=$assemblyPath',
        ...commonSnapshotArgs,
      ]);

      await assembleSnapshot(assemblyPath, snapshotPath);
    } else {
      await run(genSnapshot, <String>[
        '--no-sound-null-safety',
        '--snapshot-kind=app-aot-elf',
        '--elf=$snapshotPath',
        ...commonSnapshotArgs,
      ]);
    }

    print("Snapshot generated at $snapshotPath.");

    // May not be ELF, but another format.
    final elf = Elf.fromFile(snapshotPath);
    if (!useAsm) {
      Expect.isNotNull(elf);
    }

    if (elf != null) {
      // Verify some ELF file format parameters.
      final textSections = elf.namedSections(".text");
      Expect.isNotEmpty(textSections);
      Expect.isTrue(
          textSections.length <= 2, "More text sections than expected");
      final dataSections = elf.namedSections(".rodata");
      Expect.isNotEmpty(dataSections);
      Expect.isTrue(
          dataSections.length <= 2, "More data sections than expected");
    }

    final analyzerOutputPath = path.join(tempDir, 'analyze_test.json');

    // This will throw if exit code is not 0.
    await run(analyzeSnapshot, <String>[
      '--out=$analyzerOutputPath',
      '$snapshotPath',
    ]);

    final analyzerJsonBytes = await readFile(analyzerOutputPath);
    final analyzerJson = json.decode(analyzerJsonBytes);
    Expect.isFalse(analyzerJson.isEmpty);
    Expect.isTrue(analyzerJson.keys
        .toSet()
        .containsAll(['snapshot_data', 'objects', 'metadata']));

    final objects = (analyzerJson['objects'] as List).map((o) => o as Map);

    // Find MethodChannel class.
    final objList = objects
        .where((o) => o['type'] == 'Class' && o['name'] == 'MethodChannel')
        .toList();
    Expect.isTrue(
        objList.length == 1, 'one MethodChannel class must exist in output');
    final int objId = objList.first['id'];

    // Find string instance.
    final stringList = objects
        .where((o) => o['type'] == 'String' && o['value'] == 'constChannel1')
        .toList();
    Expect.isTrue(stringList.length == 1,
        'one "constChannel1" string must exist in output');
    final int stringObjId = stringList.first['id'];

    // Find MethodChannel instance.
    final instanceList = objects
        .where((o) =>
            o['type'] == 'Instance' &&
            o['class'] == objId &&
            o['references'].contains(stringObjId))
        .toList();
    Expect.isTrue(instanceList.length == 1, '''one instance of MethodChannel 
        with reference to "constChannel1" must exist in output''');

    Expect.isTrue(analyzerJson['metadata'].containsKey('analyzer_version'),
        'snapshot analyzer version must be reported');
    Expect.isTrue(analyzerJson['metadata']['analyzer_version'] == 2,
        'invalid snapshot analyzer version');
  });
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

  await withTempDir('analyze_snapshot_binary', (String tempDir) async {
    // We only need to generate the dill file once for all JIT tests.
    final _thisTestPath = path.join(sdkDir, 'runtime', 'tests', 'vm', 'dart',
        'analyze_snapshot_program.dart');

    // We only need to generate the dill file once for all AOT tests.
    final aotDillPath = path.join(tempDir, 'aot_test.dill');
    await run(genKernel, <String>[
      '--no-sound-null-safety',
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

    await Future.wait([
      // Test unstripped ELF generation directly.
      testAOT(aotDillPath),
      testAOT(aotDillPath, forceDrops: true),

      // Test flag-stripped ELF generation.
      testAOT(aotDillPath, stripFlag: true),
    ]);

    // Since we can't force disassembler support after the fact when running
    // in PRODUCT mode, skip any --disassemble tests. Do these tests last as
    // they have lots of output and so the log will be truncated.
    if (!const bool.fromEnvironment('dart.vm.product')) {
      // Regression test for dartbug.com/41149.
      await Future.wait([testAOT(aotDillPath, disassemble: true)]);
    }

    // Test unstripped ELF generation that is then externally stripped.
    await Future.wait([
      testAOT(aotDillPath, stripUtil: true),
    ]);

    // Dont test assembled snapshot for simulated platforms
    if (!buildDir.endsWith("SIMARM64") && !buildDir.endsWith("SIMARM64C")) {
      await Future.wait([
        // Test unstripped assembly generation that is then externally stripped.
        testAOT(aotDillPath, useAsm: true),
        // Test stripped assembly generation that is then externally stripped.
        testAOT(aotDillPath, useAsm: true, stripFlag: true),
      ]);
    }
  });
}

Future<String> readFile(String file) {
  return new File(file).readAsString();
}
