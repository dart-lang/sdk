// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

final dartAotExecutable = Uri.parse(Platform.resolvedExecutable)
    .resolve('dartaotruntime')
    .toFilePath();
final dart2wasmSnapshot = Uri.parse(Platform.resolvedExecutable)
    .resolve('snapshots/dart2wasm_product.snapshot')
    .toFilePath();
final wasmOptExecutable = Uri.parse(Platform.resolvedExecutable)
    .resolve('utils/wasm-opt')
    .toFilePath();
final platformDill = Uri.parse(Platform.resolvedExecutable)
    .resolve('../lib/_internal/dart2wasm_platform.dill')
    .toFilePath();

Future<void> run(List<String> command,
    {bool throwOutputOnFailure = false}) async {
  print('Running: ${command.join(' ')}');
  final result = await Process.run(command.first, command.skip(1).toList());
  if (result.exitCode != 0) {
    if (throwOutputOnFailure) {
      throw '${result.stdout}\n${result.stderr}';
    }

    print('-> Failed with exit code ${result.exitCode}');
    print('-> stdout:\n${result.stdout}');
    print('-> stderr:\n${result.stderr}');
    throw 'Subprocess failed';
  }
}

Future withTempDir(Future Function(String directory) fun) async {
  final dir = Directory.systemTemp.createTempSync('dart2wasm_self_compile');
  try {
    print('Running with temporary directory: ${dir.path}');
    return await fun(dir.path);
  } finally {
    if (!keepTemporaryDirectory) {
      dir.deleteSync(recursive: true);
    }
  }
}

final bool keepTemporaryDirectory =
    (Platform.environment['KEEP_TEMPORARY_DIRECTORIES'] ?? 'false') != 'false';
