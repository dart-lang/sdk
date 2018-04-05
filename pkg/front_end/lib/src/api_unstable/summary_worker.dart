// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API needed by `utils/front_end/summary_worker.dart`, a tool used to compute
/// summaries in build systems like bazel, pub-build, and package-build.

import 'dart:async' show Future;

import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart';
import 'compiler_state.dart';

export 'compiler_state.dart';

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;
export '../fasta/fasta_codes.dart' show FormattedMessage;
export '../fasta/severity.dart' show Severity;

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    Uri sdkSummary,
    Uri packagesFile,
    List<Uri> inputSummaries,
    Target target,
    FileSystem fileSystem) async {
  // TODO(sigmund): use incremental compiler when it supports our use case.
  // Note: it is common for the summary worker to invoke the compiler with the
  // same input summary URIs, but with different contents, so we'd need to be
  // able to track shas or modification time-stamps to be able to invalidate the
  // old state appropriately.
  CompilerOptions options = new CompilerOptions()
    ..sdkSummary = sdkSummary
    ..packagesFileUri = packagesFile
    ..inputSummaries = inputSummaries
    ..target = target
    ..fileSystem = fileSystem
    ..chaseDependencies = true;

  ProcessedOptions processedOpts = new ProcessedOptions(options, true, []);

  return new InitializedCompilerState(options, processedOpts);
}

Future<List<int>> compile(InitializedCompilerState compilerState,
    List<Uri> inputs, ProblemHandler problemHandler) async {
  CompilerOptions options = compilerState.options;
  options..onProblem = problemHandler;

  ProcessedOptions processedOpts = compilerState.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);

  var result = await generateKernel(processedOpts,
      buildSummary: true, buildComponent: false, truncateSummary: true);
  return result?.summary;
}
