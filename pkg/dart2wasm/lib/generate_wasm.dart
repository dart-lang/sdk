// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;
import 'package:front_end/src/api_unstable/vm.dart' show printDiagnosticMessage;

import 'compile.dart';
import 'compiler_options.dart';
import 'io_util.dart';

export 'package:dart2wasm/compiler_options.dart';

typedef PrintError = void Function(String error);

Future<int> generateWasm(WasmCompilerOptions options,
    {PrintError errorPrinter = print}) async {
  options.validate();
  final translatorOptions = options.translatorOptions;
  if (translatorOptions.verbose) {
    print('Running dart compile wasm...');
    print('  - input file name   = ${options.mainUri}');
    print('  - output file name  = ${options.outputFile}');
    print('  - librariesSpecPath = ${options.librariesSpecPath}');
    print('  - packagesPath file = ${options.packagesPath}');
    print('  - platformPath file = ${options.platformPath}');
    print('  - strip wasm = ${options.stripWasm}');
    print('  - wasm-opt path = ${options.wasmOptPath}');
    print(
        '  - max active wasm-opt processes = ${options.maxActiveWasmOptProcesses}');
    print('');
    print('Translator options:');
    print('  - enable asserts = ${translatorOptions.enableAsserts}');
    print('  - import shared memory = ${translatorOptions.importSharedMemory}');
    print('  - inlining = ${translatorOptions.inlining}');
    print('  - js compatibility = ${translatorOptions.jsCompatibility}');
    print(
        '  - omit implicit type checks = ${translatorOptions.omitImplicitTypeChecks}');
    print(
        '  - omit explicit type checks = ${translatorOptions.omitExplicitTypeChecks}');
    print('  - omit bounds checks = ${translatorOptions.omitBoundsChecks}');
    print(
        '  - polymorphic specialization = ${translatorOptions.polymorphicSpecialization}');
    print('  - print kernel = ${translatorOptions.printKernel}');
    print('  - print wasm = ${translatorOptions.printWasm}');
    print('  - minify = ${translatorOptions.minify}');
    print('  - verity type checks = ${translatorOptions.verifyTypeChecks}');
    print(
        '  - enable experimental ffi = ${translatorOptions.enableExperimentalFfi}');
    print(
        '  - enable experimental wasm interop = ${translatorOptions.enableExperimentalWasmInterop}');
    print('  - generate source maps = ${translatorOptions.generateSourceMaps}');
    print(
        '  - enable deferred loading = ${translatorOptions.enableDeferredLoading}');
    print(
        '  - enable multi module stress test mode = ${translatorOptions.enableMultiModuleStressTestMode}');
    print('  - inlining limit = ${translatorOptions.inliningLimit}');
    print(
        '  - shared memory max pages = ${translatorOptions.sharedMemoryMaxPages}');
    print(
        '  - watch points = [${translatorOptions.watchPoints.map((p) => p.toString()).join(',')}]');
  }

  final fileSystem = StandardFileSystem.instance;
  CompilationResult result = await compile(
      options, CompilerPhaseInputOutputManager(fileSystem, options), (message) {
    if (!options.dryRun) printDiagnosticMessage(message, errorPrinter);
  });

  if (result is CompilationDryRunResult) {
    assert(options.dryRun);
    if (result is CompilationDryRunError) {
      return 254;
    }
    return 0;
  }

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

  return 0;
}
