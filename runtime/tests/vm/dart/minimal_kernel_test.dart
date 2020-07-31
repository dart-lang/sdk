// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=minimal_kernel_script.dart

// Tests that dill file produced with --minimal-kernel option
// works as expected.

import 'dart:io' show Platform;

import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

compileAndRunMinimalDillTest(List<String> extraCompilationArgs) async {
  final testScriptUri = Platform.script.resolve('minimal_kernel_script.dart');
  final message = 'Round_trip_message';

  await withTempDir((String temp) async {
    final minimalDillPath = path.join(temp, 'minimal.dill');
    await runGenKernel('BUILD MINIMAL DILL FILE', [
      '--minimal-kernel',
      '--no-link-platform',
      ...extraCompilationArgs,
      '--output=$minimalDillPath',
      testScriptUri.toFilePath(),
    ]);

    final result =
        await runDart('RUN FROM MINIMAL DILL FILE', [minimalDillPath, message]);
    expectOutput(message, result);
  });
}

main() async {
  await compileAndRunMinimalDillTest([]);
}
