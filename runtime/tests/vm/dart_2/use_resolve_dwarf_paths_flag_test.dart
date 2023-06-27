// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test checks that --resolve-dwarf-paths outputs absolute and relative
// paths in DWARF information.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
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

  runTests(obfuscate: false);
  runTests(obfuscate: true);
}

void runTests({bool obfuscate}) async {
  final pathSuffix = obfuscate ? 'obfuscated' : 'cleartext';
  await withTempDir('dwarf-flag-test-$pathSuffix', (String tempDir) async {
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

    final scriptDwarfSnapshot = path.join(tempDir, 'dwarf.so');
    await run(genSnapshot, <String>[
      if (obfuscate) ...[
        '--obfuscate',
        '--save-obfuscation-map=${path.join(tempDir, 'obfuscation.map')}',
      ],
      '--no-sound-null-safety',
      '--resolve-dwarf-paths',
      '--dwarf-stack-traces-mode',
      '--snapshot-kind=app-aot-elf',
      '--elf=$scriptDwarfSnapshot',
      scriptDill,
    ]);

    // Run the resulting Dwarf-AOT compiled script.
    final dwarfTrace = await runError(dartPrecompiledRuntime, <String>[
      scriptDwarfSnapshot,
      scriptDill,
    ]);

    final tracePCOffsets = collectPCOffsets(dwarfTrace);

    // Check that translating the DWARF stack trace (without internal frames)
    // matches the symbolic stack trace.
    final dwarf = Dwarf.fromFile(scriptDwarfSnapshot);
    Expect.isNotNull(dwarf);
    checkDwarfInfo(dwarf, tracePCOffsets);
  });
}

void checkDwarfInfo(Dwarf dwarf, Iterable<PCOffset> offsets) {
  final filenames = <String>{};
  for (final offset in offsets) {
    final callInfo = offset.callInfoFrom(dwarf);
    Expect.isNotNull(callInfo);
    Expect.isNotEmpty(callInfo);
    for (final e in callInfo) {
      Expect.isTrue(e is DartCallInfo, 'Call is not from the Dart source: $e.');
      final entry = e as DartCallInfo;
      var filename = entry.filename;
      if (!filename.startsWith('/')) {
        filename = path.join(sdkDir, filename);
      }
      if (filenames.add(filename)) {
        Expect.isTrue(
            File(filename).existsSync(), 'File $filename does not exist.');
      }
    }
  }
  print('Checked filenames:');
  for (final filename in filenames) {
    print('- ${filename}');
  }
  Expect.isNotEmpty(filenames);
}
