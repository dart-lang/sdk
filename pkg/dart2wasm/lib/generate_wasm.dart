// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart' show printDiagnosticMessage;

import 'compile.dart';
import 'compiler_options.dart';

export 'package:dart2wasm/compiler_options.dart';

typedef PrintError = void Function(String error);

Future<int> generateWasm(WasmCompilerOptions options,
    {PrintError errorPrinter = print}) async {
  if (options.translatorOptions.verbose) {
    print('Running dart compile wasm...');
    print('  - input file name   = ${options.mainUri}');
    print('  - output file name  = ${options.outputFile}');
    print('  - librariesSpecPath = ${options.librariesSpecPath}');
    print('  - packagesPath file = ${options.packagesPath}');
    print('  - platformPath file = ${options.platformPath}');
  }

  CompilerOutput? output = await compileToModule(
      options, (message) => printDiagnosticMessage(message, errorPrinter));

  if (output == null) {
    return 1;
  }

  final File outFile = File(options.outputFile);
  outFile.parent.createSync(recursive: true);
  await outFile.writeAsBytes(output.wasmModule);

  final jsFile = options.outputJSRuntimeFile ??
      '${options.outputFile.substring(0, options.outputFile.lastIndexOf('.'))}.mjs';
  await File(jsFile).writeAsString(output.jsRuntime);

  return 0;
}
