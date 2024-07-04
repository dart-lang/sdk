// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart' show printDiagnosticMessage;
import 'package:path/path.dart' as path;

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
    print(
        '  - generate source maps = ${options.translatorOptions.generateSourceMaps}');
  }

  final relativeSourceMapUrl = options.translatorOptions.generateSourceMaps
      ? Uri.file('${path.basename(options.outputFile)}.map')
      : null;

  CompilerOutput? output = await compileToModule(options, relativeSourceMapUrl,
      (message) => printDiagnosticMessage(message, errorPrinter));

  if (output == null) {
    return 1;
  }

  final File outFile = File(options.outputFile);
  outFile.parent.createSync(recursive: true);
  await outFile.writeAsBytes(output.wasmModule);

  final jsFile = options.outputJSRuntimeFile ??
      path.setExtension(options.outputFile, '.mjs');
  await File(jsFile).writeAsString(output.jsRuntime);

  final sourceMap = output.sourceMap;
  if (sourceMap != null) {
    await File('${options.outputFile}.map').writeAsString(sourceMap);
  }

  return 0;
}
