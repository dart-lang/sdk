// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=bytecode_with_ast_in_aot_test_body1.dart
// OtherResources=bytecode_with_ast_in_aot_test_body2.dart

// Tests that gen_kernel is able to produce dill file with both bytecode
// and AST in AOT mode, and gen_snapshot is able to consume them.
// Two test cases are only different in number of entry points, so
// obfuscation prohibitions metadata has different size, causing
// different alignment of bytecode metadata.

import 'dart:io' show Platform;

import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

testAOTOnBytecodeWithAST(String temp, String source) async {
  final sourcePath = Platform.script.resolve(source).toFilePath();
  final dillPath = path.join(temp, '${source}.dill');
  final snapshotPath = path.join(temp, '${source}.so');

  final genKernelResult = await runGenKernel('BUILD DILL FILE', [
    '--aot',
    '--gen-bytecode',
    '--no-drop-ast',
    '--output=$dillPath',
    sourcePath,
  ]);
  print(genKernelResult);
  final genSnapshotResult = await runGenSnapshot('GENERATE SNAPSHOT', [
    '--use-bytecode-compiler',
    '--snapshot-kind=app-aot-elf',
    '--elf=$snapshotPath',
    dillPath,
  ]);
  print(genSnapshotResult);
  final runResult =
      await runBinary('RUN SNAPSHOT', dartPrecompiledRuntime, [snapshotPath]);
  expectOutput("OK", runResult);
}

main() async {
  await withTempDir((String temp) async {
    await testAOTOnBytecodeWithAST(
        temp, 'bytecode_with_ast_in_aot_test_body1.dart');
    await testAOTOnBytecodeWithAST(
        temp, 'bytecode_with_ast_in_aot_test_body2.dart');
  });
}
