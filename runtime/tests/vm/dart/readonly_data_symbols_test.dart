// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that gen_snapshot outputs static symbols for read-only
// data objects.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
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
  if (!await testExecutable(aotRuntime)) {
    throw "Cannot run test as $aotRuntime not available";
  }
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }

  await withTempDir('readonly-symbols-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script =
        path.join(cwDir, 'use_save_debugging_info_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    final scriptSnapshot = path.join(tempDir, 'dwarf.so');
    final scriptDebuggingInfo = path.join(tempDir, 'debug_info.so');
    await run(genSnapshot, <String>[
      '--dwarf-stack-traces-mode',
      '--save-debugging-info=$scriptDebuggingInfo',
      '--snapshot-kind=app-aot-elf',
      '--elf=$scriptSnapshot',
      scriptDill,
    ]);

    checkElf(scriptSnapshot);
    checkElf(scriptDebuggingInfo);
  });
}

void checkElf(String filename) {
  // Check that the static symbol table contains entries that are not in the
  // dynamic symbol table, have STB_LOCAL binding, and are of type STT_OBJECT.
  final elf = Elf.fromFile(filename);
  Expect.isNotNull(elf);
  final dynamicSymbols = elf!.dynamicSymbols.toList();
  for (final symbol in dynamicSymbols) {
    // All symbol tables have an initial entry with zero-valued fields.
    if (symbol.name == '') {
      Expect.equals(SymbolBinding.STB_LOCAL, symbol.bind);
      Expect.equals(SymbolType.STT_NOTYPE, symbol.type);
      Expect.equals(0, symbol.value);
    } else {
      Expect.equals(SymbolBinding.STB_GLOBAL, symbol.bind);
      Expect.equals(SymbolType.STT_OBJECT, symbol.type);
      Expect.isTrue(symbol.name.startsWith('_kDart'),
          'unexpected symbol name ${symbol.name}');
    }
  }
  final onlyStaticSymbols = elf.staticSymbols
      .where((s1) => !dynamicSymbols.any((s2) => s1.name == s2.name));
  Expect.isNotEmpty(onlyStaticSymbols, 'no static-only symbols');
  final objectSymbols =
      onlyStaticSymbols.where((s) => s.type == SymbolType.STT_OBJECT);
  Expect.isNotEmpty(objectSymbols, 'no static-only object symbols');
  for (final symbol in objectSymbols) {
    // Currently we only write local object symbols.
    Expect.equals(SymbolBinding.STB_LOCAL, symbol.bind);
    // All object symbols are prefixed with the type of the C++ object.
    final objectType = symbol.name.substring(0, symbol.name.indexOf('_'));
    switch (objectType) {
      // Used for entries in the non-clustered portion of the read-only data
      // section that don't correspond to a specific Dart object.
      case 'RawBytes':
      // Currently the only types of objects written to the non-clustered
      // portion of the read-only data section.
      case 'OneByteString':
      case 'TwoByteString':
      case 'CodeSourceMap':
      case 'PcDescriptors':
      case 'CompressedStackMaps':
        break;
      default:
        Expect.fail('unexpected object type $objectType');
    }
  }
}
