// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that the AOT compiler can generate stripped versions of
// snapshots. For assembly and COFF outputs this test is currently very weak,
// in that it just checks that the stripped version is strictly smaller than
// the unstripped one.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:io";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'package:smith/smith.dart';
import 'package:native_stack_traces/elf.dart' as elf;
import 'package:native_stack_traces/src/macho.dart' as macho;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }

  await withTempDir('strip-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    // We can just reuse the program for the use_save_debugging_info_flag test.
    final script = path.join(
      cwDir,
      'use_save_debugging_info_flag_program.dart',
    );
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    for (final format in GenSnapshotFormat.values) {
      // TODO(dartbug.com/64732): Add COFF-appropriate checking (including
      // for the Windows assembly case) in compareStrippedAndUnstripped and
      // then only skip COFF on non-Windows platforms and don't skip assembly.
      if (format == GenSnapshotFormat.coff) {
        print('Skipping COFF output until test appropriately extended.');
        continue;
      }
      if (format == GenSnapshotFormat.assembly && Platform.isWindows) {
        print(
          'Skipping Windows assembly output until test appropriately '
          'extended.',
        );
        continue;
      }
      await runTestCase(tempDir, scriptDill, format);
    }
  });
}

class TestCase(final GenSnapshotFormat format, final String outputPath);

Future<void> runTestCase(
  String tempDir,
  String scriptDill,
  GenSnapshotFormat format,
) async {
  final prefix = format.fileOption;
  final unstrippedSnapshot = path.join(tempDir, '$prefix-whole.so');
  await run(genSnapshot, [
    '--snapshot-kind=${format.snapshotType}',
    '--${format.fileOption}=$unstrippedSnapshot',
    scriptDill,
  ]);
  final unstrippedCase = TestCase(format, unstrippedSnapshot);

  final strippedSnapshot = path.join(tempDir, '$prefix-stripped.so');
  await run(genSnapshot, [
    '--strip',
    '--snapshot-kind=${format.snapshotType}',
    '--${format.fileOption}=$strippedSnapshot',
    scriptDill,
  ]);
  final strippedCase = TestCase(format, strippedSnapshot);

  compareStrippedAndUnstripped(
    stripped: strippedCase,
    unstripped: unstrippedCase,
  );
}

void compareStrippedAndUnstripped({
  required TestCase stripped,
  required TestCase unstripped,
}) {
  Expect.equals(stripped.format, unstripped.format);
  print('Testing stripped and unstripped ${stripped.format} outputs.');
  switch (stripped.format) {
    case GenSnapshotFormat.coff:
      Expect.fail("COFF is currently untested.");
      break;
    case GenSnapshotFormat.assembly:
      if (Platform.isWindows) {
        Expect.fail("Assembly output on Windows is currently untested.");
      }
      // For assembly outputs on other platforms, just compare the file sizes
      // for now.
      final strippedSize = File(stripped.outputPath).lengthSync();
      final unstrippedSize = File(unstripped.outputPath).lengthSync();
      print(
        "File size for stripped file ${stripped.outputPath}: $strippedSize",
      );
      print(
        "File size for stripped file ${unstripped.outputPath}: $unstrippedSize",
      );
      Expect.isTrue(strippedSize < unstrippedSize);
      break;
    case GenSnapshotFormat.machODylib:
      final strippedMachO = macho.MachO.fromFile(stripped.outputPath);
      Expect.isNotNull(strippedMachO);
      final strippedSymbols = strippedMachO!.symbolTable;
      print('Stripped symbol table size: ${strippedSymbols.keys.length}');
      final unstrippedMachO = macho.MachO.fromFile(unstripped.outputPath);
      Expect.isNotNull(unstrippedMachO);
      final unstrippedSymbols = unstrippedMachO!.symbolTable;
      print('Unstripped symbol table size: ${unstrippedSymbols.keys.length}');
      // The stripped symbol table should be a strict subset of the unstripped one.
      print('External symbols:');
      for (final name in strippedSymbols.keys) {
        print(' * $name');
        Expect.isTrue(strippedSymbols[name]!.isExternal);
        Expect.isTrue(strippedSymbols[name]!.isSection);
        Expect.isNotNull(unstrippedSymbols[name]);
      }
      Expect.isTrue(
        strippedSymbols.keys.length < unstrippedSymbols.keys.length,
      );
      break;
    case GenSnapshotFormat.elf:
      final strippedElf = elf.Elf.fromFile(stripped.outputPath);
      Expect.isNotNull(strippedElf);
      final strippedDynamicSymbols = strippedElf!.dynamicSymbols;
      print('Stripped dynamic symbol count: ${strippedDynamicSymbols.length}');
      Expect.isNotEmpty(strippedDynamicSymbols);
      final strippedStaticSymbols = strippedElf.staticSymbols;
      print('Stripped static symbol count: ${strippedStaticSymbols.length}');
      Expect.isEmpty(strippedStaticSymbols);

      final unstrippedElf = elf.Elf.fromFile(unstripped.outputPath);
      Expect.isNotNull(unstrippedElf);
      final unstrippedDynamicSymbols = unstrippedElf!.dynamicSymbols;
      print(
        'Unstripped dynamic symbol count: ${unstrippedDynamicSymbols.length}',
      );
      Expect.isNotEmpty(unstrippedDynamicSymbols);
      final unstrippedStaticSymbols = unstrippedElf.staticSymbols;
      print(
        'Unstripped static symbol count: ${unstrippedStaticSymbols.length}',
      );
      Expect.isNotEmpty(unstrippedStaticSymbols);

      Expect.isTrue(
        strippedDynamicSymbols.length == unstrippedDynamicSymbols.length,
      );
      final sortedStrippedDynamicSymbols = strippedDynamicSymbols.toList()
        ..sort((s1, s2) => s1.name.compareTo(s2.name));
      final sortedUnstrippedDynamicSymbols = unstrippedDynamicSymbols.toList()
        ..sort((s1, s2) => s1.name.compareTo(s2.name));
      print('Dynamic symbols:');
      for (int i = 0; i < sortedStrippedDynamicSymbols.length; i++) {
        final strippedSymbol = sortedStrippedDynamicSymbols[i];
        final unstrippedSymbol = sortedUnstrippedDynamicSymbols[i];
        print(' * ${strippedSymbol.name}');
        Expect.equals(strippedSymbol.name, unstrippedSymbol.name);
      }
      break;
  }
  print('');
}
