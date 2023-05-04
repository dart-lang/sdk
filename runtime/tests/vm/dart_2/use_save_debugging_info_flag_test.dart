// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test ensures that the AOT compiler can generate debugging information
// for stripped ELF output, and that using the debugging information to look
// up stripped stack trace information matches the non-stripped version.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:io";
import "dart:math";
import "dart:typed_data";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
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

  await withTempDir('save-debug-info-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script =
        path.join(cwDir, 'use_save_debugging_info_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--no-sound-null-safety',
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    // Run the AOT compiler with Dwarf stack traces, once without stripping,
    // once with stripping, and once with stripping and saving debugging
    // information.
    final scriptWholeSnapshot = path.join(tempDir, 'whole.so');
    await run(genSnapshot, <String>[
      '--no-sound-null-safety',
      '--dwarf-stack-traces',
      '--snapshot-kind=app-aot-elf',
      '--elf=$scriptWholeSnapshot',
      scriptDill,
    ]);
    checkElf(scriptWholeSnapshot);

    final scriptStrippedOnlySnapshot = path.join(tempDir, 'stripped_only.so');
    await run(genSnapshot, <String>[
      '--no-sound-null-safety',
      '--dwarf-stack-traces',
      '--snapshot-kind=app-aot-elf',
      '--elf=$scriptStrippedOnlySnapshot',
      '--strip',
      scriptDill,
    ]);
    checkElf(scriptStrippedOnlySnapshot);

    final scriptStrippedSnapshot = path.join(tempDir, 'stripped.so');
    final scriptDebuggingInfo = path.join(tempDir, 'debug.so');
    await run(genSnapshot, <String>[
      '--no-sound-null-safety',
      '--dwarf-stack-traces',
      '--snapshot-kind=app-aot-elf',
      '--elf=$scriptStrippedSnapshot',
      '--strip',
      '--save-debugging-info=$scriptDebuggingInfo',
      scriptDill,
    ]);
    checkElf(scriptStrippedSnapshot);
    checkElf(scriptDebuggingInfo);

    // Run the resulting scripts, saving the stack traces.
    final wholeTrace = await runError(dartPrecompiledRuntime, <String>[
      scriptWholeSnapshot,
      scriptDill,
    ]);
    final wholeOffsets = collectPCOffsets(wholeTrace);

    final strippedOnlyTrace = await runError(dartPrecompiledRuntime, <String>[
      scriptStrippedOnlySnapshot,
      scriptDill,
    ]);
    final strippedOnlyOffsets = collectPCOffsets(strippedOnlyTrace);

    final strippedTrace = await runError(dartPrecompiledRuntime, <String>[
      scriptStrippedSnapshot,
      scriptDill,
    ]);
    final strippedOffsets = collectPCOffsets(strippedTrace);

    // The retrieved offsets should be the same for all runs.
    Expect.deepEquals(wholeOffsets, strippedOffsets);
    Expect.deepEquals(strippedOnlyOffsets, strippedOffsets);

    // Stripped output should not change when --save-debugging-info is used.
    compareSnapshots(scriptStrippedOnlySnapshot, scriptStrippedSnapshot);

    print('');
    print("Original stack trace:");
    strippedTrace.forEach(print);

    final debugDwarf = Dwarf.fromFile(scriptDebuggingInfo);
    final wholeDwarf = Dwarf.fromFile(scriptWholeSnapshot);

    final fromDebug = await Stream.fromIterable(strippedTrace)
        .transform(DwarfStackTraceDecoder(debugDwarf))
        .toList();
    print("\nStack trace converted using separate debugging info:");
    print(fromDebug.join('\n'));

    final fromWhole = await Stream.fromIterable(strippedTrace)
        .transform(DwarfStackTraceDecoder(wholeDwarf))
        .toList();
    print("\nStack trace converted using unstripped ELF file:");
    print(fromWhole.join('\n'));

    Expect.deepEquals(fromDebug, fromWhole);
  });
}

void compareSnapshots(String file1, String file2) {
  final bytes1 = File(file1).readAsBytesSync();
  final bytes2 = File(file2).readAsBytesSync();
  final diff = diffBinary(bytes1, bytes2);
  if (diff.isNotEmpty) {
    print("\nFound differences between $file1 and $file2:");
    printDiff(diff);
  }
  Expect.equals(bytes1.length, bytes2.length);
  Expect.equals(0, diff.length);
}

Map<int, List<int>> diffBinary(Uint8List bytes1, Uint8List bytes2) {
  final ret = Map<int, List<int>>();
  final len = min(bytes1.length, bytes2.length);
  for (var i = 0; i < len; i++) {
    if (bytes1[i] != bytes2[i]) {
      ret[i] = <int>[bytes1[i], bytes2[i]];
    }
  }
  if (bytes1.length > len) {
    for (var i = len; i < bytes1.length; i++) {
      ret[i] = <int>[bytes1[i], -1];
    }
  } else if (bytes2.length > len) {
    for (var i = len; i < bytes2.length; i++) {
      ret[i] = <int>[-1, bytes2[i]];
    }
  }
  return ret;
}

void printDiff(Map<int, List<int>> map, [int maxOutput = 100]) {
  int lines = 0;
  for (var index in map.keys) {
    final pair = map[index];
    if (pair[0] == -1) {
      print('$index: <>, ${pair[1]}');
      lines++;
    } else if (pair[1] == -1) {
      print('$index: ${pair[0]}, <>');
      lines++;
    } else {
      print('$index: ${pair[0]}, ${pair[1]}');
      lines++;
    }
    if (lines >= maxOutput) {
      return;
    }
  }
}

void checkElf(String filename) {
  print("Checking ELF file $filename:");
  final elf = Elf.fromFile(filename);
  Expect.isNotNull(elf);
  final dynamic = elf.namedSections(".dynamic").single as DynamicTable;

  // Check the dynamic string table information.
  Expect.isTrue(
      dynamic.containsKey(DynamicTableTag.DT_STRTAB), "no string table entry");
  final dynstr = elf.namedSections(".dynstr").single;
  print(".dynstr address = ${dynamic[DynamicTableTag.DT_STRTAB]}");
  Expect.isTrue(elf.sectionHasValidSegmentAddresses(dynstr),
      "string table addresses are invalid");
  Expect.equals(dynamic[DynamicTableTag.DT_STRTAB], dynstr.headerEntry.addr);
  Expect.isTrue(dynamic.containsKey(DynamicTableTag.DT_STRSZ),
      "no string table size entry");
  print(".dynstr size = ${dynamic[DynamicTableTag.DT_STRSZ]}");
  Expect.equals(dynamic[DynamicTableTag.DT_STRSZ], dynstr.headerEntry.size);

  // Check the dynamic symbol table information.
  Expect.isTrue(
      dynamic.containsKey(DynamicTableTag.DT_SYMTAB), "no symbol table entry");
  print(".dynsym address = ${dynamic[DynamicTableTag.DT_SYMTAB]}");
  final dynsym = elf.namedSections(".dynsym").single;
  Expect.isTrue(elf.sectionHasValidSegmentAddresses(dynsym),
      "string table addresses are invalid");
  Expect.equals(dynamic[DynamicTableTag.DT_SYMTAB], dynsym.headerEntry.addr);
  Expect.isTrue(dynamic.containsKey(DynamicTableTag.DT_SYMENT),
      "no symbol table entry size entry");
  print(".dynsym entry size = ${dynamic[DynamicTableTag.DT_SYMENT]}");
  Expect.equals(
      dynamic[DynamicTableTag.DT_SYMENT], dynsym.headerEntry.entrySize);

  // Check the hash table information.
  Expect.isTrue(
      dynamic.containsKey(DynamicTableTag.DT_HASH), "no hash table entry");
  print(".hash address = ${dynamic[DynamicTableTag.DT_HASH]}");
  final hash = elf.namedSections(".hash").single;
  Expect.isTrue(elf.sectionHasValidSegmentAddresses(hash),
      "hash table addresses are invalid");
  Expect.equals(dynamic[DynamicTableTag.DT_HASH], hash.headerEntry.addr);
}
