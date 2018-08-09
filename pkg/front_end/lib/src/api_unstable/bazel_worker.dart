// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API needed by `utils/front_end/summary_worker.dart`, a tool used to compute
/// summaries in build systems like bazel, pub-build, and package-build.

import 'dart:async' show Future;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/file_system.dart';
import '../base/processed_options.dart';
import '../kernel_generator_impl.dart';

import '../api_prototype/compiler_options.dart';
import 'compiler_state.dart';

export 'compiler_state.dart';

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;
export '../fasta/fasta_codes.dart' show FormattedMessage;
export '../fasta/severity.dart' show Severity;
import '../fasta/kernel/utils.dart' show serializeComponent;

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    Uri sdkSummary,
    Uri packagesFile,
    List<Uri> summaryInputs,
    List<Uri> linkedInputs,
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
    ..inputSummaries = summaryInputs
    ..linkedDependencies = linkedInputs
    ..target = target
    ..fileSystem = fileSystem;

  ProcessedOptions processedOpts = new ProcessedOptions(options, []);

  return new InitializedCompilerState(options, processedOpts);
}

Future<List<int>> compile(InitializedCompilerState compilerState,
    List<Uri> inputs, ProblemHandler problemHandler,
    {bool summaryOnly}) async {
  summaryOnly ??= true;
  CompilerOptions options = compilerState.options;
  options..onProblem = problemHandler;

  ProcessedOptions processedOpts = compilerState.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);

  var result = await generateKernel(processedOpts,
      buildSummary: summaryOnly, buildComponent: !summaryOnly);

  var component = result?.component;
  if (component != null && !summaryOnly) {
    for (var lib in component.libraries) {
      if (!inputs.contains(lib.importUri)) {
        // Excluding the library also means that their canonical names will not
        // be computed as part of serialization, so we need to do that
        // preemtively here to avoid errors when serializing references to
        // elements of these libraries.
        component.root.getChildFromUri(lib.importUri).bindTo(lib.reference);
        lib.computeCanonicalNames();
      }
    }
  }

  return summaryOnly
      ? result?.summary
      : serializeComponent(result?.component,
          filter: (library) => inputs.contains(library.importUri));
}
