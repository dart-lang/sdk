// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';

import '../snapshot_test_helper.dart';
import '../../../concurrency/generate_stress_test.dart'
    show testFilesNnbd, generateStressTest;

// The only purpose of the test is to ensure we can generate a isolate stress
// test out of many normal dart tests (that are expected to be short-lived and
// passing).
//
// The actual isolate stress test is run on it's own builder (similar to our
// fuzzing test).
main() async {
  if (!Platform.isLinux) return;
  if (!Platform.executable.endsWith("ReleaseX64/dart")) return;

  final dartExecutable = Platform.executable;
  await withTempDir((String tempDir) async {
    final stressTest = path.join(tempDir, 'stress_test.dart');
    final stressTestDill = path.join(tempDir, 'stress_test.dill');

    // Generate stress test.
    File(stressTest).writeAsStringSync(await generateStressTest(testFilesNnbd));

    final packageConfig =
        path.join(path.absolute('.'), '.dart_tool/package_config.json');

    // Compile stress test to kernel.
    final args = [
      '--packages=$packageConfig',
      '--snapshot-kind=kernel',
      '--no-sound-null-safety',
      '--snapshot=$stressTestDill',
      stressTest
    ];
    print('Running $dartExecutable ${args.join(' ')}');
    final process = await Process.start(dartExecutable, args);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      stdout.writeln(line);
    });
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      stderr.writeln(line);
    });
    Expect.equals(0, await process.exitCode);
  });
}
