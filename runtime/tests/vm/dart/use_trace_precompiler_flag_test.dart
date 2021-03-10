// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that --trace-precompiler runs without issue and prints
// valid JSON for reasons to retain objects.

// OtherResources=use_dwarf_stack_traces_flag_program.dart

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
  if (!await testExecutable(aotRuntime)) {
    throw "Cannot run test as $aotRuntime not available";
  }
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }

  await withTempDir('trace-precompiler-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    // We can just reuse the program for the use_dwarf_stack_traces test.
    final script = path.join(cwDir, 'use_dwarf_stack_traces_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
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
      await testTracePrecompiler(scriptDill, flags);
    }
  });
}

const _jsonHeaders = {'JSON for function decisions: '};

Future<void> testTracePrecompiler(String scriptDill, List<String> flags) async {
  final result = await runHelper(genSnapshot, <String>[
    ...flags,
    '--trace-precompiler',
    '--snapshot-kind=app-aot-elf',
    '--elf=snapshot.so',
    scriptDill,
  ]);

  Expect.equals(result.exitCode, 0);

  // Tracing output is on stderr.
  Expect.isTrue(result.stdout.isEmpty);
  Expect.isTrue(result.stderr.isNotEmpty);

  final seenHeaders = <String>{};
  final lines =
      Stream.value(result.stderr as String).transform(const LineSplitter());
  await for (final s in lines) {
    for (final header in _jsonHeaders) {
      if (s.startsWith(header)) {
        // We only expect a single instance of each header.
        Expect.isFalse(seenHeaders.contains(header),
            'multiple instances of \"$header\" seen');
        seenHeaders.add(header);
        final j = s.substring(header.length);
        // For now, just test that the JSON parses and that we get back a list.
        Expect.isTrue(json.decode(j) is List, 'not a list of decisions');
      }
    }
  }
  // Check that all headers were seen in the output.
  for (final header in _jsonHeaders) {
    Expect.isTrue(
        seenHeaders.contains(header), 'no instance of \"$header\" seen');
  }
}
