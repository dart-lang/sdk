// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This test ensures that --trace-precompiler runs without issue and prints
// valid JSON for reasons to retain objects.

// OtherResources=use_save_debugging_info_flag_program.dart

import "dart:convert";
import "dart:io";

import 'package:expect/expect.dart';
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

  await withTempDir('trace-precompiler-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    // We can just reuse the program for the use_save_debugging_info_flag test.
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

    // Run the AOT compiler with every enabled/disabled combination of the
    // following flags that affect object retention:
    final retentionFlags = [
      'retain-function-objects',
      'dwarf-stack-traces-mode'
    ];

    for (var i = 0; i < 1 << retentionFlags.length; i++) {
      final flags = <String>[];
      for (var j = 0; j < retentionFlags.length; j++) {
        final buffer = StringBuffer('--');
        if ((i & (1 << j)) == 0) {
          buffer.write('no-');
        }
        buffer.write(retentionFlags[j]);
        flags.add(buffer.toString());
      }
      await testTracePrecompiler(tempDir, scriptDill, flags);
    }
  });
}

Future<void> testTracePrecompiler(
    String tempDir, String scriptDill, List<String> flags) async {
  final reasonsFile = path.join(tempDir, 'reasons.json');
  final snapshot = path.join(tempDir, 'snapshot.so');
  final result = await run(genSnapshot, <String>[
    ...flags,
    '--no-sound-null-safety',
    '--write-retained-reasons-to=$reasonsFile',
    '--snapshot-kind=app-aot-elf',
    '--elf=$snapshot',
    scriptDill,
  ]);

  final stream = Stream.fromFuture(File(reasonsFile).readAsString());
  final decisionsJson = await json.decoder.bind(stream).first;
  Expect.isTrue(decisionsJson is List, 'not a list of decisions');
  Expect.isTrue((decisionsJson as List).every((o) => o is Map),
      'not a list of decision objects');
  final decisions = (decisionsJson as List).map((o) => o as Map);
  for (final m in decisions) {
    Expect.isTrue(m.containsKey("name"), 'no name field in decision');
    Expect.isTrue(m["name"] is String, 'name field is not a string');
    Expect.isTrue(m.containsKey("type"), 'no type field in decision');
    Expect.isTrue(m["type"] is String, 'type field is not a string');
    Expect.isTrue(m.containsKey("retained"), 'no retained field in decision');
    Expect.isTrue(m["retained"] is bool, 'retained field is not a boolean');
    if (m["retained"] as bool) {
      Expect.isTrue(m.containsKey("reasons"), 'no reasons field in decision');
      Expect.isTrue(m["reasons"] is List, 'reasons field is not a list');
      final reasons = m["reasons"] as List;
      Expect.isFalse(reasons.isEmpty, 'reasons list should not be empty');
      for (final o in reasons) {
        Expect.isTrue(o is String, 'reason is not a string');
      }
    }
  }
}
