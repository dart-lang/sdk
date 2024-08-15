// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.memory_compiler;

import 'dart:async';

import 'package:compiler/compiler_api.dart' as api
    show CompilationResult, CompilerDiagnostics, CompilerOutput, Diagnostic;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/diagnostics/messages.dart' show Message;
import 'package:compiler/src/null_compiler_output.dart' show NullCompilerOutput;
import 'package:compiler/src/options.dart' show CompilerOptions;
import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import 'memory_source_file_helper.dart';

export 'package:compiler/compiler_api.dart' show CompilationResult;

export 'diagnostic_helper.dart';
export 'output_collector.dart';

String sdkPath = 'sdk/lib';

String sdkLibrariesSpecificationPath = '$sdkPath/libraries.json';

Uri sdkLibrariesSpecificationUri =
    Uri.base.resolve(sdkLibrariesSpecificationPath);

Uri sdkPlatformBinariesUri = fe
    .computePlatformBinariesLocation()
    .resolve("dart2js_platform.dill")
    .resolve('.');

String sdkPlatformBinariesPath = sdkPlatformBinariesUri.toString();

Uri buildPlatformBinariesUri = fe
    .computePlatformBinariesLocation(forceBuildDir: true)
    .resolve("dart2js_platform.dill")
    .resolve('.');

String buildPlatformBinariesPath = buildPlatformBinariesUri.toString();

class MultiDiagnostics implements api.CompilerDiagnostics {
  final List<api.CompilerDiagnostics> diagnosticsList;

  const MultiDiagnostics([this.diagnosticsList = const []]);

  @override
  void report(covariant Message? message, Uri? uri, int? begin, int? end,
      String text, api.Diagnostic kind) {
    for (api.CompilerDiagnostics diagnostics in diagnosticsList) {
      diagnostics.report(message, uri, begin, end, text, kind);
    }
  }
}

api.CompilerDiagnostics createCompilerDiagnostics(
    api.CompilerDiagnostics? diagnostics, SourceFileProvider provider,
    {bool showDiagnostics = true, bool verbose = false}) {
  if (showDiagnostics) {
    if (diagnostics == null) {
      diagnostics = FormattingDiagnosticHandler()
        ..verbose = verbose
        ..registerFileProvider(provider);
    } else {
      var formattingHandler = FormattingDiagnosticHandler()
        ..verbose = verbose
        ..registerFileProvider(provider);
      diagnostics = MultiDiagnostics([diagnostics, formattingHandler]);
    }
  } else if (diagnostics == null) {
    diagnostics = MultiDiagnostics();
  }
  return diagnostics;
}

// Cached kernel state.
fe.InitializedCompilerState? kernelInitializedCompilerState;

/// memorySourceFiles can contain a map of string filename to string file
/// contents or string file name to binary file contents (hence the `dynamic`
/// type for the second parameter).
Future<api.CompilationResult> runCompiler(
    {Map<String, dynamic> memorySourceFiles = const <String, dynamic>{},
    Uri? entryPoint,
    api.CompilerDiagnostics? diagnosticHandler,
    api.CompilerOutput? outputProvider,
    List<String> options = const <String>[],
    Map<String, String>? environment,
    bool showDiagnostics = true,
    Uri? librariesSpecificationUri,
    Uri? packageConfig,
    void beforeRun(Compiler compiler)?}) async {
  if (entryPoint == null) {
    entryPoint = Uri.parse('memory:main.dart');
  }
  Compiler compiler = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      diagnosticHandler: diagnosticHandler,
      outputProvider: outputProvider,
      options: options,
      environment: environment,
      showDiagnostics: showDiagnostics,
      librariesSpecificationUri: librariesSpecificationUri,
      packageConfig: packageConfig);
  if (beforeRun != null) {
    beforeRun(compiler);
  }
  bool isSuccess = await compiler.run();
  fe.InitializedCompilerState? compilerState =
      kernelInitializedCompilerState = compiler.initializedCompilerState;
  return api.CompilationResult(compiler,
      isSuccess: isSuccess, kernelInitializedCompilerState: compilerState);
}

Compiler compilerFor(
    {Uri? entryPoint,
    Map<String, dynamic> memorySourceFiles = const <String, dynamic>{},
    api.CompilerDiagnostics? diagnosticHandler,
    api.CompilerOutput? outputProvider,
    List<String> options = const <String>[],
    Map<String, String>? environment,
    bool showDiagnostics = true,
    Uri? librariesSpecificationUri,
    Uri? packageConfig}) {
  retainDataForTesting = true;
  librariesSpecificationUri ??= sdkLibrariesSpecificationUri;

  if (packageConfig == null) {
    if (Platform.packageConfig != null) {
      packageConfig = Uri.base.resolve(Platform.packageConfig!);
    } else {
      // The tests are run with the base directory as the SDK root
      // so just use the package config there.
      packageConfig = Uri.base.resolve('.dart_tool/package_config.json');
    }
  }

  // Create a local in case we end up cloning memorySourceFiles.
  Map<String, dynamic> sources = memorySourceFiles;

  MemorySourceFileProvider provider;
  provider = MemorySourceFileProvider(sources);
  diagnosticHandler = createCompilerDiagnostics(diagnosticHandler, provider,
      showDiagnostics: showDiagnostics,
      verbose: options.contains('-v') || options.contains('--verbose'));

  if (outputProvider == null) {
    outputProvider = const NullCompilerOutput();
  }

  options = [...options, '${Flags.entryUri}=$entryPoint'];

  CompilerOptions compilerOptions = CompilerOptions.parse(options,
      librariesSpecificationUri: librariesSpecificationUri)
    ..environment = environment ?? {}
    ..packageConfig = packageConfig;

  compilerOptions.setDefaultOutputUriForTesting();
  compilerOptions.kernelInitializedCompilerState =
      kernelInitializedCompilerState;
  var compiler =
      Compiler(provider, outputProvider, diagnosticHandler, compilerOptions);

  return compiler;
}

void main() {
  runCompiler(memorySourceFiles: {'main.dart': 'main() {}'});
}
