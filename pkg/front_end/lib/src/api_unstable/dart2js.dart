// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Program;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, ErrorHandler;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/fasta_codes.dart' show messageMissingMain;

import '../fasta/parser.dart' show noLength;

import '../fasta/severity.dart' show Severity;

import '../kernel_generator_impl.dart' show generateKernelInternal;

import 'compiler_state.dart' show InitializedCompilerState;

export 'compiler_state.dart' show InitializedCompilerState;

InitializedCompilerState initializeCompiler(InitializedCompilerState oldState,
    Target target, Uri sdkUri, Uri packagesFileUri) {
  if (oldState != null &&
      oldState.options.packagesFileUri == packagesFileUri &&
      oldState.options.linkedDependencies[0] == sdkUri) {
    return oldState;
  }

  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..strongMode = target.strongMode
    ..linkedDependencies = [sdkUri]
    ..packagesFileUri = packagesFileUri;

  ProcessedOptions processedOpts = new ProcessedOptions(options, false, []);

  return new InitializedCompilerState(options, processedOpts);
}

Future<Program> compile(InitializedCompilerState state, bool verbose,
    FileSystem fileSystem, ErrorHandler onError, Uri input) async {
  CompilerOptions options = state.options;
  options
    ..onError = onError
    ..verbose = verbose
    ..fileSystem = fileSystem;

  ProcessedOptions processedOpts = state.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.add(input);
  processedOpts.clearFileSystemCache();

  var compilerResult = await CompilerContext.runWithOptions(processedOpts,
      (CompilerContext context) async {
    var compilerResult = await generateKernelInternal();
    Program program = compilerResult?.program;
    if (program == null) return null;
    if (program.mainMethod == null) {
      context.options.report(
          messageMissingMain.withLocation(input, -1, noLength), Severity.error);
      return null;
    }
    return compilerResult;
  });

  return compilerResult?.program;
}
