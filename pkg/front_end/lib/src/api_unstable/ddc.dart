// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessageHandler;

import 'package:kernel/class_hierarchy.dart';

import 'package:kernel/kernel.dart' show Component, Library;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../api_prototype/kernel_generator.dart' show CompilerResult;

import '../api_prototype/standard_file_system.dart' show StandardFileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../base/nnbd_mode.dart' show NnbdMode;

import '../kernel_generator_impl.dart' show generateKernel;

import 'compiler_state.dart' show InitializedCompilerState;

import 'modular_incremental_compilation.dart' as modular
    show initializeIncrementalCompiler;

import 'util.dart' show equalLists, equalMaps;

export 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage;

export 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

export '../api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags, parseExperimentalArguments;

export '../api_prototype/experimental_flags.dart'
    show ExperimentalFlag, parseExperimentalFlag;

export '../api_prototype/kernel_generator.dart' show kernelForModule;

export '../api_prototype/lowering_predicates.dart';

export '../api_prototype/memory_file_system.dart' show MemoryFileSystem;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../base/processed_options.dart' show ProcessedOptions;

export '../base/nnbd_mode.dart' show NnbdMode;

export '../fasta/compiler_context.dart' show CompilerContext;

export '../fasta/incremental_compiler.dart' show IncrementalCompiler;

export '../fasta/kernel/redirecting_factory_body.dart'
    show RedirectingFactoryBody, isRedirectingFactoryField, redirectingName;

export '../fasta/type_inference/type_schema_environment.dart'
    show TypeSchemaEnvironment;

export 'compiler_state.dart'
    show InitializedCompilerState, WorkerInputComponent, digestsEqual;

class DdcResult {
  final Component component;
  final Component sdkSummary;
  final List<Component> additionalDills;
  final ClassHierarchy classHierarchy;

  DdcResult(this.component, this.sdkSummary, this.additionalDills,
      this.classHierarchy)
      : assert(classHierarchy != null);

  Set<Library> computeLibrariesFromDill() {
    Set<Library> librariesFromDill = new Set<Library>();

    for (Component c in additionalDills) {
      for (Library lib in c.libraries) {
        librariesFromDill.add(lib);
      }
    }
    if (sdkSummary != null) {
      for (Library lib in sdkSummary.libraries) {
        librariesFromDill.add(lib);
      }
    }

    return librariesFromDill;
  }
}

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    bool compileSdk,
    Uri sdkRoot,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> additionalDills,
    Target target,
    {FileSystem fileSystem,
    Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    Map<String, String> environmentDefines,
    NnbdMode nnbdMode}) async {
  assert(nnbdMode != null, "No NnbdMode provided.");
  additionalDills.sort((a, b) => a.toString().compareTo(b.toString()));

  if (oldState != null &&
      oldState.options.compileSdk == compileSdk &&
      oldState.options.sdkSummary == sdkSummary &&
      oldState.options.packagesFileUri == packagesFile &&
      oldState.options.librariesSpecificationUri == librariesSpecificationUri &&
      oldState.options.nnbdMode == nnbdMode &&
      equalLists(oldState.options.additionalDills, additionalDills) &&
      equalMaps(oldState.options.explicitExperimentalFlags,
          explicitExperimentalFlags) &&
      equalMaps(oldState.options.environmentDefines, environmentDefines)) {
    // Reuse old state.
    return oldState;
  }

  CompilerOptions options = new CompilerOptions()
    ..compileSdk = compileSdk
    ..sdkRoot = sdkRoot
    ..sdkSummary = sdkSummary
    ..packagesFileUri = packagesFile
    ..additionalDills = additionalDills
    ..librariesSpecificationUri = librariesSpecificationUri
    ..target = target
    ..fileSystem = fileSystem ?? StandardFileSystem.instance
    ..environmentDefines = environmentDefines
    ..nnbdMode = nnbdMode;
  if (explicitExperimentalFlags != null) {
    options.explicitExperimentalFlags = explicitExperimentalFlags;
  }

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
    List<Component> doneAdditionalDills,
    bool compileSdk,
    Uri sdkRoot,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> additionalDills,
    Map<Uri, List<int>> workerInputDigests,
    Target target,
    {FileSystem fileSystem,
    Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    Map<String, String> environmentDefines,
    bool trackNeededDillLibraries: false,
    NnbdMode nnbdMode}) async {
  return modular.initializeIncrementalCompiler(
      oldState,
      tags,
      doneAdditionalDills,
      sdkSummary,
      packagesFile,
      librariesSpecificationUri,
      additionalDills,
      workerInputDigests,
      target,
      compileSdk: compileSdk,
      sdkRoot: sdkRoot,
      fileSystem: fileSystem ?? StandardFileSystem.instance,
      explicitExperimentalFlags: explicitExperimentalFlags,
      environmentDefines:
          environmentDefines ?? const <ExperimentalFlag, bool>{},
      outlineOnly: false,
      omitPlatform: false,
      trackNeededDillLibraries: trackNeededDillLibraries,
      nnbdMode: nnbdMode);
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

  // These should be cached.
  Component sdkSummary = await processedOpts.loadSdkSummary(null);
  List<Component> summaries = await processedOpts.loadAdditionalDills(null);
  return new DdcResult(
      component, sdkSummary, summaries, compilerResult.classHierarchy);
}
