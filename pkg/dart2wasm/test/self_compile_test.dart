// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

Future main() async {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  final benchmarkFile = 'pkg/dart2wasm/benchmark/self_compile_benchmark.dart';

  await withTempDir((String tempDir) async {
    final outFilename = path.join(tempDir, 'out');
    final outVmFilename = path.join(tempDir, 'out.vm');
    final outDart2WasmFilename = path.join(tempDir, 'out.dart2wasm');
    final outFile = File(outFilename);

    // Run [benchmarkFile] via VM & capture output.
    await run([Platform.executable, benchmarkFile, outFilename]);
    final vmBytes = outFile.readAsBytesSync();
    outFile.renameSync(outVmFilename);

    // Run [benchmarkFile] via Dart2Wasm+D8 & capture output.
    final selfCompiler = path.join(tempDir, 'self_compile_benchmark.wasm');
    await run([
      Platform.executable,
      'compile',
      'wasm',
      '-O2',
      '--no-strip-wasm',
      '--no-minify',
      benchmarkFile,
      '-o',
      selfCompiler
    ]);
    await run(['pkg/dart2wasm/tool/run_benchmark', selfCompiler, outFilename]);
    final wasmBytes = outFile.readAsBytesSync();
    outFile.renameSync(outDart2WasmFilename);

    if (vmBytes.length != wasmBytes.length) {
      throw 'Mismatch in length ${vmBytes.length} vs ${wasmBytes.length}';
    }
    for (int i = 0; i < vmBytes.length; ++i) {
      if (vmBytes[i] != wasmBytes[i]) {
        throw 'Mismatch at offset $i ${vmBytes[i]} vs ${wasmBytes[i]}';
      }
    }
  });
}

Future run(List<String> command) async {
  print('Running: ${command.join(' ')}');
  final result = await Process.run(command.first, command.skip(1).toList());
  if (result.exitCode != 0) {
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
