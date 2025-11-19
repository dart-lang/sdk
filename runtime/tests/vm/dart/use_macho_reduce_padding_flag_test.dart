// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that using the --macho-reduce-padding flag actually
// reduces the padding used for segments and text/const sections in Mach-O
// outputs.

import "dart:async";
import "dart:io";

import 'package:native_stack_traces/src/macho.dart' show MachO, SegmentCommand;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'use_flag_test_helper.dart';

Future<void> main() async {
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

  await withTempDir('macho-reduce-padding', (String tempDir) async {
    // We have to use the program in its original location so it can use
    // the dart:_internal library (as opposed to adding it as an OtherResources
    // option to the test).
    final scriptPath = path.join(
      sdkDir,
      'runtime',
      'tests',
      'vm',
      'dart',
      'use_dwarf_stack_traces_flag_program.dart',
    );
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      scriptPath,
    ]);

    final defaultPaddingTestCase = await createTestCase(
      tempDir,
      scriptDill,
      'default_padding',
      14,
      const [],
    );

    final reducedPaddingTestCase = await createTestCase(
      tempDir,
      scriptDill,
      'reduced_padding',
      6,
      const ['--macho-reduce-padding'],
    );

    test(
      "Testing default MachO padding",
      checkTestCase(defaultPaddingTestCase),
    );

    test(
      "Testing reduced MachO padding",
      checkTestCase(reducedPaddingTestCase),
    );
  });
}

class TestCase {
  int segmentAlignment;
  MachO snapshot;
  MachO debugInfo;
  MachO relocatableObject;

  TestCase(
    this.segmentAlignment,
    this.snapshot,
    this.debugInfo,
    this.relocatableObject,
  );
}

Future<TestCase> createTestCase(
  String tempDir,
  String scriptDill,
  String prefix,
  int alignment,
  List<String> extraArgs,
) async {
  final dsymutil = llvmTool('dsymutil', verbose: true)!;

  print("Generating Mach-O snapshots with segment alignment ${1 << alignment}");
  final snapshotPath = path.join(tempDir, '$prefix.dylib');
  final objectPath = path.join(tempDir, '$prefix.o');
  final debugInfoPath = path.join(tempDir, 'debug_info_$prefix.so');
  await run(genSnapshot, <String>[
    '--dwarf-stack-traces-mode',
    '--save-debugging-info=$debugInfoPath',
    '--snapshot-kind=app-aot-macho-dylib',
    '--macho=$snapshotPath',
    '--macho-object=$objectPath',
    ...extraArgs,
    scriptDill,
  ]);

  // Make sure dsymutil doesn't have any issue with the snapshot or
  // relocatable object.
  print("Generating dSYM for segment alignment ${1 << alignment}");
  final dsymPath = path.join(tempDir, '$prefix.dSYM');
  await run(dsymutil, ['-o', dsymPath, snapshotPath]);

  return TestCase(
    alignment,
    MachO.fromFile(snapshotPath)!,
    MachO.fromFile(debugInfoPath)!,
    MachO.fromFile(objectPath)!,
  );
}

int align(int n, int alignLog2) {
  final alignment = 1 << alignLog2;
  final extra = n % alignment;
  final padding = (extra == 0) ? 0 : (alignment - extra);
  return n + padding;
}

void Function() checkTestCase(TestCase testCase) => () {
  for (final macho in [
    testCase.snapshot,
    testCase.debugInfo,
    testCase.relocatableObject,
  ]) {
    for (final segment in macho.commandsWhereType<SegmentCommand>()) {
      print(segment);
      // Skip the linkedit segment, which isn't padded to a specific alignment.
      if (segment.segname == '__LINKEDIT') continue;
      int contentsSize = 0;
      if (segment.segname == '__TEXT') {
        // The header and load commands are contained within the initial (text)
        // segment for non-relocatable objects.
        contentsSize += macho.header.size + macho.header.sizeofcmds;
      }
      for (final section in segment.sectionsInOrder) {
        expect(
          section.align,
          lessThanOrEqualTo(testCase.segmentAlignment),
          reason:
              'Section "${section.segname}", "${section.sectname}" has '
              'an alignment of ${section.align} > ${testCase.segmentAlignment}',
        );
        contentsSize = align(contentsSize, section.align);
        contentsSize += section.size;
      }
      expect(
        segment.filesize,
        lessThanOrEqualTo(align(contentsSize, testCase.segmentAlignment)),
      );
    }
  }
};
