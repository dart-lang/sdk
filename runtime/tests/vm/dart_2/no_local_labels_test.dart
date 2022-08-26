// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that assembly snapshot does not contain local labels.
// (labels starting with 'L').

// @dart=2.9

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

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

  await withTempDir('no-local-labels-test', (String tempDir) async {
    final script = path.join(tempDir, 'program.dart');
    final scriptDill = path.join(tempDir, 'program.dill');

    await File(script).writeAsString('''
class Local {
  @pragma('vm:never-inline')
  void foo() {
  }

  @pragma('vm:never-inline')
  void bar() {
  }
}

void main(List<String> args) {
  Local()..foo()..bar();
}
''');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    if (Platform.isWindows) {
      return; // No assembly generation on Windows.
    }

    final assembly = path.join(tempDir, 'program.S');
    await run(genSnapshot, <String>[
      '--snapshot-kind=app-aot-assembly',
      '--assembly=$assembly',
      scriptDill,
    ]);

    final localLabelRe = RegExp(r'^L[a-zA-Z0-9_\.$]*:$', multiLine: true);
    final match = localLabelRe.firstMatch(await File(assembly).readAsString());
    if (match != null) {
      Expect.isTrue(false, 'unexpected local label found ${match[0]}');
    }
  });
}
