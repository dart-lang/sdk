// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:io";

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and gen_snapshot not available on the test device.
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

  await withTempDir('dwarf-flag-test', (String dir) async {
    File(path.join(dir, 'main.dart')).writeAsStringSync('''
        import 'dart:isolate';
        main(List<String> args) async {
          final rp = ReceivePort();
          try {
            await Isolate.spawnUri(Uri.parse(args.single), <String>[], rp.sendPort);
            final result = await rp.first;
            if (result != 'hello from spawnee') throw 'failed';
            print('got spawnee message');
            print('success');
          } finally {
            rp.close();
          }
        }
    ''');
    for (final basename in ['spawnee', 'spawnee_checked']) {
      File(path.join(dir, '$basename.dart')).writeAsStringSync('''
          import 'dart:isolate';
          main(List<String> args, dynamic sendPort) {
            print('spawnee started');
            (sendPort as SendPort).send('hello from spawnee');
          }
      ''');
    }

    // '--enable-asserts' is not available in product mode, so we skip the
    // negative test.
    final isProductMode = const bool.fromEnvironment('dart.vm.product');

    for (final basename in ['main', 'spawnee', 'spawnee_checked']) {
      final script = path.join(dir, '$basename.dart');
      final scriptDill = path.join(dir, '$basename.dart.dill');
      final bool checked = basename.endsWith('_checked');

      if (isProductMode && checked) continue;

      await run(genKernel, <String>[
        if (checked) '--enable-asserts',
        '--aot',
        '--platform=$platformDill',
        '-o',
        scriptDill,
        script,
      ]);

      final scriptAot = path.join(dir, '$basename.dart.dill.so');
      await run(genSnapshot, <String>[
        if (checked) '--enable-asserts',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptAot',
        scriptDill,
      ]);
    }

    // Successful run
    final result1 = await runOutput(dartPrecompiledRuntime, <String>[
      path.join(dir, 'main.dart.dill.so'),
      path.join(dir, 'spawnee.dart.dill.so'),
    ]);
    Expect.deepEquals([
      'spawnee started',
      'got spawnee message',
      'success',
    ], result1);

    if (!isProductMode) {
      // File exists and is AOT snapshot but was compiled with different flags
      // (namely --enable-asserts)
      final result2 = await runHelper(dartPrecompiledRuntime, [
        path.join(dir, 'main.dart.dill.so'),
        path.join(dir, 'spawnee_checked.dart.dill.so'),
      ]);
      Expect.notEquals(0, result2.exitCode);
      Expect.contains(
          'Snapshot not compatible with the current VM configuration',
          result2.stderr);
    }

    // File does not exist.
    final result3 = await runHelper(dartPrecompiledRuntime, [
      path.join(dir, 'main.dart.dill.so'),
      path.join(dir, 'does_not_exist.dart.dill.so'),
    ]);
    Expect.notEquals(0, result3.exitCode);
    Expect.contains(
        'The uri provided to `Isolate.spawnUri()` does not contain a valid AOT '
        'snapshot',
        result3.stderr);
  });
}
