// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=bytecode_and_ast_mix_test_body.dart

// Tests the mix of kernel AST (test) and bytecode dill files (core libraries).
// Verifies that kernel AST can reference a not yet loaded bytecode class
// through a constant in metadata.

import 'dart:io' show Platform;

import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

main() async {
  final testScriptUri =
      Platform.script.resolve('bytecode_and_ast_mix_test_body.dart');
  await withTempDir((String temp) async {
    final dillPath = path.join(temp, 'ast.dill');
    final testPath = testScriptUri.toFilePath();

    final buildResult = await runGenKernel('BUILD AST DILL FILE', [
      '--no-gen-bytecode',
      '--output=$dillPath',
      testPath,
    ]);
    print(buildResult);
    final runResult = await runDart('RUN FROM AST DILL FILE', [dillPath]);
    expectOutput("OK", runResult);
  });
}
