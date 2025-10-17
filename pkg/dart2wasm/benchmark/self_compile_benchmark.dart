// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;
import 'package:dart2wasm/compile.dart';
import 'package:dart2wasm/compiler_options.dart';

import 'filesystem_io.dart' if (dart.library.js_interop) 'filesystem_js.dart';

Future main(List<String> args) async {
  final sw = Stopwatch()..start();
  final fileSystem = WasmCompilerFileSystem();
  final result = await compileBenchmark(
      fileSystem, 'pkg/dart2wasm/benchmark/self_compile_benchmark.dart');
  print('Dart2WasmSelfCompile(RunTimeRaw): ${sw.elapsed.inMilliseconds} ms.');

  if (args.isNotEmpty) {
    final module = result.wasmModules.values.single;
    final wasmFile = args.single;
    fileSystem.writeBytesSync(wasmFile, module.moduleBytes);
  }
}

Future<CodegenResult> compileBenchmark(
    WasmCompilerFileSystem fileSystem, String mainFile) async {
  // Avoid CFE self-detecting whether `stdout`/`stderr` is terminal and supports
  // colors (as we don't have `dart:io` available when we run dart2wasm in a
  // wasm runtime).
  colors.enableColors = false;

  final main = Uri.file('${fileSystem.sdkRoot}/$mainFile');

  final options = WasmCompilerOptions(mainUri: main, outputFile: 'out.wasm');
  options.librariesSpecPath =
      Uri.file('${fileSystem.sdkRoot}/sdk/lib/libraries.json');

  final result = await compile(
      options, fileSystem, (mod) => Uri.parse('$mod.maps'), (diag) {
    print('Diagnostics: ${diag.severity} ${diag.plainTextFormatted}');
  });
  if (result is! CompilationSuccess) {
    throw 'Compilation Failed: $result';
  }
  return result as CodegenResult;
}
