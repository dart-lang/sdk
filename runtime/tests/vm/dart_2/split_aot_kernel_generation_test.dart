// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=splay_test.dart

// Tests AOT kernel generation split into 2 steps using '--from-dill' option.

import 'dart:io' show Platform;

import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

Future<void> runSplitAOTKernelGenerationTest(Uri testScriptUri) async {
  await withTempDir((String temp) async {
    final intermediateDillPath = path.join(temp, 'intermediate.dill');
    final outputDillPath = path.join(temp, 'output.dill');
    final snapshotPath = path.join(temp, 'aot.snapshot');

    await runGenKernel('BUILD INTERMEDIATE DILL FILE', [
      '--no-aot',
      '--link-platform',
      '--output=$intermediateDillPath',
      testScriptUri.toFilePath(),
    ]);

    await runGenKernel('BUILD FINAL DILL FILE', [
      '--aot',
      '--from-dill=$intermediateDillPath',
      '--link-platform',
      '--output=$outputDillPath',
      testScriptUri.toFilePath(),
    ]);

    await runGenSnapshot('GENERATE SNAPSHOT', [
      '--snapshot-kind=app-aot-elf',
      '--elf=$snapshotPath',
      outputDillPath,
    ]);

    await runBinary('RUN SNAPSHOT', dartPrecompiledRuntime, [snapshotPath]);
  });
}

main() async {
  await runSplitAOTKernelGenerationTest(
      Platform.script.resolve('splay_test.dart'));
}
