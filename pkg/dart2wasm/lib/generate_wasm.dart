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

  String moduleNameToWasmOutputFile(String moduleName) {
    final outputFile = options.outputFile;
    if (moduleName.isEmpty) return outputFile;
    final extension = path.extension(outputFile);
    return path.setExtension(outputFile, '_$moduleName$extension');
  }

  String moduleNameToSourceMapFile(String moduleName) {
    return '${moduleNameToWasmOutputFile(moduleName)}.map';
  }

  Uri moduleNameToRelativeSourceMapUri(String moduleName) {
    return Uri.file(path.basename(moduleNameToSourceMapFile(moduleName)));
  }

  final relativeSourceMapUrlMapper =
      options.translatorOptions.generateSourceMaps
          ? moduleNameToRelativeSourceMapUri
          : null;

  CompilationResult result =
      await compileToModule(options, relativeSourceMapUrlMapper, (message) {
    printDiagnosticMessage(message, errorPrinter);
  });

  // If the compilation to wasm failed we use appropriate exit codes recognized
  // by our test infrastructure. We use the same exit codes as the VM does. See:
  //    runtime/bin/error_exit.h:kDartFrontendErrorExitCode
  //    runtime/bin/error_exit.h:kCompilationErrorExitCode
  //    runtime/bin/error_exit.h:kErrorExitCode
  if (result is! CompilationSuccess) {
    if (result is CFECrashError) {
      print('The compiler crashed with: ${result.error}');
      print(result.stackTrace);
      return 252;
    }
    if (result is CFECompileTimeErrors) {
      return 254;
    }

    return 255;
  }

  final writeFutures = <Future>[];
  result.wasmModules.forEach((moduleName, moduleInfo) {
    final (:moduleBytes, :sourceMap) = moduleInfo;
    final File outFile = File(moduleNameToWasmOutputFile(moduleName));
    outFile.parent.createSync(recursive: true);
    writeFutures.add(outFile.writeAsBytes(moduleBytes));

    if (sourceMap != null) {
      writeFutures.add(
          File(moduleNameToSourceMapFile(moduleName)).writeAsString(sourceMap));
    }
  });
  await Future.wait(writeFutures);

  final jsFile = options.outputJSRuntimeFile ??
      path.setExtension(options.outputFile, '.mjs');
  await File(jsFile).writeAsString(result.jsRuntime);

  return 0;
}
