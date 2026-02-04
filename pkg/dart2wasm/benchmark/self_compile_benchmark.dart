// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;
import 'package:dart2wasm/compile.dart';
import 'package:dart2wasm/compiler_options.dart';
import 'package:dart2wasm/io_util.dart';

import 'filesystem_io.dart' if (dart.library.js_interop) 'filesystem_js.dart';

class _BenchmarkIOManager extends CompilerPhaseInputOutputManager {
  final WasmCompilerFileSystem benchmarkFileSystem;
  Uint8List? moduleBytes;

  _BenchmarkIOManager(this.benchmarkFileSystem, WasmCompilerOptions options)
      : super(benchmarkFileSystem, options);

  @override
  Future<void> writeWasmModule(Uint8List wasmModule, String moduleName) async {
    moduleBytes = wasmModule;
  }

  @override
  Future<void> writeWasmSourceMap(String sourceMap, String moduleName) async {}

  @override
  Future<void> writeJsRuntime(String jsRuntime) async {}

  @override
  Future<void> writeSupportJs(String supportJs) async {}

  void flushWasmModules(String wasmFile) {
    benchmarkFileSystem.writeBytesSync(wasmFile, moduleBytes!);
  }
}

Future main(List<String> args) async {
  final sw = Stopwatch()..start();
  final fileSystem = WasmCompilerFileSystem();
  final mainFile = 'pkg/dart2wasm/benchmark/self_compile_benchmark.dart';
  final main = Uri.file('${fileSystem.sdkRoot}/$mainFile');

  final options = WasmCompilerOptions(mainUri: main, outputFile: 'out.wasm');
  final ioManager = _BenchmarkIOManager(fileSystem, options);

  options.librariesSpecPath =
      Uri.file('${fileSystem.sdkRoot}/sdk/lib/libraries.json');

  await compileBenchmark(options, ioManager);
  print('Dart2WasmSelfCompile(RunTimeRaw): ${sw.elapsed.inMilliseconds} ms.');

  if (args.isNotEmpty) {
    final wasmFile = args.single;
    ioManager.flushWasmModules(wasmFile);
  }
}

Future<CodegenResult> compileBenchmark(WasmCompilerOptions options,
    CompilerPhaseInputOutputManager ioManager) async {
  // Avoid CFE self-detecting whether `stdout`/`stderr` is terminal and supports
  // colors (as we don't have `dart:io` available when we run dart2wasm in a
  // wasm runtime).
  colors.enableColors = false;

  final result = await compile(options, ioManager, (diag) {
    print('Diagnostics: ${diag.severity} ${diag.plainTextFormatted}');
  });
  if (result is! CompilationSuccess) {
    throw 'Compilation Failed: $result';
  }
  return result as CodegenResult;
}
