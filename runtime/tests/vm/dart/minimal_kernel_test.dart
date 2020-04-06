// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that dill file produced with --minimal-kernel option
// works as expected.

import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

compileAndRunMinimalDillTest(List<String> extraCompilationArgs) async {
  await withTempDir((String temp) async {
    final expectedOutput =
        (await runDart('RUN FROM SOURCE', [genKernel, '--help'])).output;

    final minimalDillPath = path.join(temp, 'minimal.dill');
    await runGenKernel('BUILD MINIMAL DILL FILE', [
      '--minimal-kernel',
      '--no-link-platform',
      ...extraCompilationArgs,
      '--output=$minimalDillPath',
      genKernel,
    ]);

    final result1 = await runDart(
        'RUN FROM MINIMAL DILL FILE', [minimalDillPath, '--help']);
    expectOutput(expectedOutput, result1);
  });
}

main() async {
  await compileAndRunMinimalDillTest([]);
}
