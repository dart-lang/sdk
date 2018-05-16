// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Component;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, ErrorHandler;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/fasta_codes.dart' show messageMissingMain, noLength;

import '../fasta/severity.dart' show Severity;

import '../kernel_generator_impl.dart' show generateKernelInternal;

import 'compiler_state.dart' show InitializedCompilerState;

export 'compiler_state.dart' show InitializedCompilerState;

InitializedCompilerState initializeCompiler(
    InitializedCompilerState oldState,
    Target target,
    Uri librariesSpecificationUri,
    Uri sdkPlatformUri,
    Uri packagesFileUri) {
  if (oldState != null &&
      oldState.options.packagesFileUri == packagesFileUri &&
      oldState.options.librariesSpecificationUri == librariesSpecificationUri &&
      oldState.options.linkedDependencies[0] == sdkPlatformUri) {
    return oldState;
  }

  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..strongMode = target.strongMode
    ..linkedDependencies = [sdkPlatformUri]
    ..librariesSpecificationUri = librariesSpecificationUri
    ..packagesFileUri = packagesFileUri;

  ProcessedOptions processedOpts = new ProcessedOptions(options, false, []);

  return new InitializedCompilerState(options, processedOpts);
}

Future<Component> compile(InitializedCompilerState state, bool verbose,
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
    Component component = compilerResult?.component;
    if (component == null) return null;
    if (component.mainMethod == null) {
      context.options.report(
          messageMissingMain.withLocation(input, -1, noLength), Severity.error);
      return null;
    }
    return compilerResult;
  });

  return compilerResult?.component;
}
