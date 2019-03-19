// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API needed by `utils/front_end/summary_worker.dart`, a tool used to compute
/// summaries in build systems like bazel, pub-build, and package-build.

import 'dart:async' show Future;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessageHandler;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/kernel/utils.dart' show serializeComponent;

import '../kernel_generator_impl.dart' show generateKernel;

import 'compiler_state.dart' show InitializedCompilerState;

export '../api_prototype/diagnostic_message.dart' show DiagnosticMessage;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../fasta/severity.dart' show Severity;

export 'compiler_state.dart' show InitializedCompilerState;

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    Uri sdkSummary,
    Uri librariesSpecificationUri,
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
    ..librariesSpecificationUri = librariesSpecificationUri
    ..inputSummaries = summaryInputs
    ..linkedDependencies = linkedInputs
    ..target = target
    ..fileSystem = fileSystem;

  ProcessedOptions processedOpts = new ProcessedOptions(options: options);

  return new InitializedCompilerState(options, processedOpts);
}

Future<List<int>> compile(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler,
    {bool summaryOnly}) async {
  summaryOnly ??= true;
  CompilerOptions options = compilerState.options;
  options..onDiagnostic = diagnosticMessageHandler;

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
        // preemptively here to avoid errors when serializing references to
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
