// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:convert";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!Platform.executable.endsWith("dart_precompiled_runtime")) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and gen_snapshot not available on the test device.
  }

  final scriptUrl = path.join(
    sdkDir,
    'runtime',
    'tests',
    'vm',
    'dart',
    'gen_snapshot_include_resolved_urls_script.dart',
  );

  late Directory tempDir;
  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('aot-script-urls-test');
    final scriptDill = path.join(tempDir.path, 'test.dill');

    // Compile script to Kernel IR.
    await run('pkg/vm/tool/gen_kernel', <String>[
      '--aot',
      '--packages=$sdkDir/.dart_tool/package_config.json',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      scriptUrl,
    ]);
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  // Let the test runner handle timeouts.
  test(
    'Include resolved urls',
    () async {
      final scriptDill = path.join(tempDir.path, 'test.dill');

      // Compile script to Kernel IR.
      await run('pkg/vm/tool/gen_kernel', <String>[
        '--aot',
        '--packages=$sdkDir/.packages',
        '--platform=$platformDill',
        '-o',
        scriptDill,
        scriptUrl,
      ]);

      final elfFile = path.join(tempDir.path, 'aot.snapshot');
      await run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-elf',
        '--elf=$elfFile',
        scriptDill,
      ]);

      // Ensure we can actually run the code.
      expect(
        await run(dartPrecompiledRuntime, <String>[
          '--enable-vm-service=0',
          '--profiler',
          elfFile,
        ]),
        true,
      );
    },
    timeout: Timeout.none,
  );
}

Future<String> readFile(String file) {
  return File(file).readAsString();
}

Future<bool> run(String executable, List<String> args) async {
  print('Running $executable ${args.join(' ')}');

  final result = await Process.run(executable, args);
  final String stdout = result.stdout;
  final String stderr = result.stderr;
  if (stdout.isNotEmpty) {
    print('stdout:');
    print(stdout);
  }
  if (stderr.isNotEmpty) {
    print('stderr:');
    print(stderr);
  }

  if (result.exitCode != 0) {
    print('Command failed with non-zero exit code (was ${result.exitCode})');
    return false;
  }
  return result.stdout.contains('SUCCESS') && stderr.isEmpty;
}
