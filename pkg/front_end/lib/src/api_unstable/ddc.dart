// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Component;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessageHandler;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../api_prototype/standard_file_system.dart' show StandardFileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../kernel_generator_impl.dart' show generateKernel;

import 'compiler_state.dart' show InitializedCompilerState;

export '../api_prototype/compiler_options.dart' show CompilerOptions;

export '../api_prototype/diagnostic_message.dart' show DiagnosticMessage;

export '../api_prototype/experimental_flags.dart'
    show ExperimentalFlag, parseExperimentalFlag;

export '../api_prototype/kernel_generator.dart' show kernelForComponent;

export '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../fasta/kernel/redirecting_factory_body.dart'
    show RedirectingFactoryBody;

export '../fasta/severity.dart' show Severity;

export '../fasta/type_inference/type_schema_environment.dart'
    show TypeSchemaEnvironment;

export 'compiler_state.dart' show InitializedCompilerState;

class DdcResult {
  final Component component;
  final List<Component> inputSummaries;

  DdcResult(this.component, this.inputSummaries);
}

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> inputSummaries,
    Target target,
    {FileSystem fileSystem,
    Map<ExperimentalFlag, bool> experiments}) async {
  inputSummaries.sort((a, b) => a.toString().compareTo(b.toString()));
  bool listEqual(List<Uri> a, List<Uri> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; ++i) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool mapEqual(Map<ExperimentalFlag, bool> a, Map<ExperimentalFlag, bool> b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var flag in a.keys) {
      if (!b.containsKey(flag) || a[flag] != b[flag]) return false;
    }
    return true;
  }

  if (oldState != null &&
      oldState.options.sdkSummary == sdkSummary &&
      oldState.options.packagesFileUri == packagesFile &&
      oldState.options.librariesSpecificationUri == librariesSpecificationUri &&
      listEqual(oldState.options.inputSummaries, inputSummaries) &&
      mapEqual(oldState.options.experimentalFlags, experiments)) {
    // Reuse old state.

    // These libraries are marked external when compiling. If not un-marking
    // them compilation will fail.
    // Remove once [kernel_generator_impl.dart] no longer marks the libraries
    // as external.
    (await oldState.processedOpts.loadSdkSummary(null))
        .libraries
        .forEach((lib) => lib.isExternal = false);
    (await oldState.processedOpts.loadInputSummaries(null))
        .forEach((p) => p.libraries.forEach((lib) => lib.isExternal = false));

    return oldState;
  }

  CompilerOptions options = new CompilerOptions()
    ..sdkSummary = sdkSummary
    ..packagesFileUri = packagesFile
    ..inputSummaries = inputSummaries
    ..librariesSpecificationUri = librariesSpecificationUri
    ..target = target
    ..fileSystem = fileSystem ?? StandardFileSystem.instance;
  if (experiments != null) options.experimentalFlags = experiments;

  ProcessedOptions processedOpts = new ProcessedOptions(options: options);

  return new InitializedCompilerState(options, processedOpts);
}

Future<DdcResult> compile(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler) async {
  CompilerOptions options = compilerState.options;
  options..onDiagnostic = diagnosticMessageHandler;

  ProcessedOptions processedOpts = compilerState.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);

  var compilerResult = await generateKernel(processedOpts);

  var component = compilerResult?.component;
  if (component == null) return null;

  // This should be cached.
  var summaries = await processedOpts.loadInputSummaries(null);
  return new DdcResult(component, summaries);
}
