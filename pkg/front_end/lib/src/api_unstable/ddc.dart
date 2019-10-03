// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/class_hierarchy.dart';

import 'package:kernel/kernel.dart' show Component;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessageHandler;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../api_prototype/kernel_generator.dart' show CompilerResult;

import '../api_prototype/standard_file_system.dart' show StandardFileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../kernel_generator_impl.dart' show generateKernel;

import 'compiler_state.dart' show InitializedCompilerState;

import 'modular_incremental_compilation.dart' as modular
    show initializeIncrementalCompiler;

import 'util.dart' show equalLists, equalMaps;

export '../api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags, parseExperimentalArguments;

export '../api_prototype/diagnostic_message.dart' show DiagnosticMessage;

export '../api_prototype/experimental_flags.dart'
    show ExperimentalFlag, parseExperimentalFlag;

export '../api_prototype/kernel_generator.dart' show kernelForModule;

export '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../base/processed_options.dart' show ProcessedOptions;

export '../fasta/compiler_context.dart' show CompilerContext;

export '../fasta/incremental_compiler.dart' show IncrementalCompiler;

export '../fasta/kernel/redirecting_factory_body.dart'
    show RedirectingFactoryBody;

export '../fasta/severity.dart' show Severity;

export '../fasta/type_inference/type_schema_environment.dart'
    show TypeSchemaEnvironment;

export 'compiler_state.dart'
    show InitializedCompilerState, WorkerInputComponent, digestsEqual;

class DdcResult {
  final Component component;
  final List<Component> inputSummaries;
  final ClassHierarchy classHierarchy;

  DdcResult(this.component, this.inputSummaries, this.classHierarchy)
      : assert(classHierarchy != null);
}

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    bool compileSdk,
    Uri sdkRoot,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> inputSummaries,
    Target target,
    {FileSystem fileSystem,
    Map<ExperimentalFlag, bool> experiments,
    Map<String, String> environmentDefines}) async {
  inputSummaries.sort((a, b) => a.toString().compareTo(b.toString()));

  if (oldState != null &&
      oldState.options.compileSdk == compileSdk &&
      oldState.options.sdkSummary == sdkSummary &&
      oldState.options.packagesFileUri == packagesFile &&
      oldState.options.librariesSpecificationUri == librariesSpecificationUri &&
      equalLists(oldState.options.inputSummaries, inputSummaries) &&
      equalMaps(oldState.options.experimentalFlags, experiments) &&
      equalMaps(oldState.options.environmentDefines, environmentDefines)) {
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
    ..compileSdk = compileSdk
    ..sdkRoot = sdkRoot
    ..sdkSummary = sdkSummary
    ..packagesFileUri = packagesFile
    ..inputSummaries = inputSummaries
    ..librariesSpecificationUri = librariesSpecificationUri
    ..target = target
    ..fileSystem = fileSystem ?? StandardFileSystem.instance
    ..environmentDefines = environmentDefines;
  if (experiments != null) options.experimentalFlags = experiments;

  ProcessedOptions processedOpts = new ProcessedOptions(options: options);

  return new InitializedCompilerState(options, processedOpts);
}

/// Initializes the compiler for a modular build.
///
/// Re-uses cached components from [oldState.workerInputCache], and reloads them
/// as necessary based on [workerInputDigests].
Future<InitializedCompilerState> initializeIncrementalCompiler(
    InitializedCompilerState oldState,
    Set<String> tags,
    List<Component> doneInputSummaries,
    bool compileSdk,
    Uri sdkRoot,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> inputSummaries,
    Map<Uri, List<int>> workerInputDigests,
    Target target,
    {FileSystem fileSystem,
    Map<ExperimentalFlag, bool> experiments,
    Map<String, String> environmentDefines,
    bool trackNeededDillLibraries: false}) async {
  return modular.initializeIncrementalCompiler(
      oldState,
      tags,
      doneInputSummaries,
      sdkSummary,
      packagesFile,
      librariesSpecificationUri,
      inputSummaries,
      workerInputDigests,
      target,
      compileSdk: compileSdk,
      sdkRoot: sdkRoot,
      fileSystem: fileSystem ?? StandardFileSystem.instance,
      experimentalFlags: experiments,
      environmentDefines:
          environmentDefines ?? const <ExperimentalFlag, bool>{},
      outlineOnly: false,
      omitPlatform: false,
      trackNeededDillLibraries: trackNeededDillLibraries);
}

Future<DdcResult> compile(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler) async {
  CompilerOptions options = compilerState.options;
  options..onDiagnostic = diagnosticMessageHandler;

  ProcessedOptions processedOpts = compilerState.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);

  CompilerResult compilerResult =
      await generateKernel(processedOpts, includeHierarchyAndCoreTypes: true);

  Component component = compilerResult?.component;
  if (component == null) return null;

  // This should be cached.
  List<Component> summaries = await processedOpts.loadInputSummaries(null);
  return new DdcResult(component, summaries, compilerResult.classHierarchy);
}
