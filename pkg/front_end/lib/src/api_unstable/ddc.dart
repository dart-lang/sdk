// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Component, CanonicalName;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessageHandler;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../api_prototype/standard_file_system.dart' show StandardFileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/incremental_compiler.dart' show IncrementalCompiler;

import '../kernel_generator_impl.dart' show generateKernel;

import 'compiler_state.dart'
    show InitializedCompilerState, WorkerInputComponent, digestsEqual;

import 'util.dart' show equalLists, equalMaps;

export '../api_prototype/compiler_options.dart' show CompilerOptions;

export '../api_prototype/diagnostic_message.dart' show DiagnosticMessage;

export '../api_prototype/experimental_flags.dart'
    show ExperimentalFlag, parseExperimentalFlag;

export '../api_prototype/kernel_generator.dart' show kernelForComponent;

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

  DdcResult(this.component, this.inputSummaries);
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

Future<InitializedCompilerState> initializeIncrementalCompiler(
    InitializedCompilerState oldState,
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
    Map<String, String> environmentDefines}) async {
  inputSummaries.sort((a, b) => a.toString().compareTo(b.toString()));

  IncrementalCompiler incrementalCompiler;
  WorkerInputComponent cachedSdkInput;
  CompilerOptions options;
  ProcessedOptions processedOpts;

  Map<Uri, WorkerInputComponent> workerInputCache =
      oldState?.workerInputCache ?? new Map<Uri, WorkerInputComponent>();
  var sdkDigest = workerInputDigests[sdkSummary];
  if (sdkDigest == null) {
    throw new StateError("Expected to get sdk digest at $sdkSummary");
  }

  cachedSdkInput = workerInputCache[sdkSummary];

  if (oldState == null ||
      oldState.incrementalCompiler == null ||
      oldState.options.compileSdk != compileSdk ||
      cachedSdkInput == null ||
      !digestsEqual(cachedSdkInput.digest, sdkDigest) ||
      !equalMaps(oldState.options.experimentalFlags, experiments) ||
      !equalMaps(oldState.options.environmentDefines, environmentDefines)) {
    // No previous state.
    options = new CompilerOptions()
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

    // We'll load a new sdk, anything loaded already will have a wrong root.
    workerInputCache.clear();

    processedOpts = new ProcessedOptions(options: options);

    cachedSdkInput = new WorkerInputComponent(
        sdkDigest, await processedOpts.loadSdkSummary(null));
    workerInputCache[sdkSummary] = cachedSdkInput;
    incrementalCompiler = new IncrementalCompiler.fromComponent(
        new CompilerContext(processedOpts), cachedSdkInput.component);
  } else {
    options = oldState.options;
    options.inputSummaries = inputSummaries;
    processedOpts = oldState.processedOpts;

    for (var lib in cachedSdkInput.component.libraries) {
      lib.isExternal = false;
    }
    cachedSdkInput.component.adoptChildren();
    for (WorkerInputComponent cachedInput in workerInputCache.values) {
      cachedInput.component.adoptChildren();
    }

    // Reuse the incremental compiler, but reset as needed.
    incrementalCompiler = oldState.incrementalCompiler;
    incrementalCompiler.invalidateAllSources();
    options.packagesFileUri = packagesFile;
    options.fileSystem = fileSystem;
    processedOpts.clearFileSystemCache();
  }
  InitializedCompilerState compilerState = new InitializedCompilerState(
      options, processedOpts,
      workerInputCache: workerInputCache,
      incrementalCompiler: incrementalCompiler);

  CanonicalName nameRoot = cachedSdkInput.component.root;
  List<int> loadFromDillIndexes = new List<int>();

  // Notice that the ordering of the input summaries matter, so we need to
  // keep them in order.
  if (doneInputSummaries.length != inputSummaries.length) {
    throw new ArgumentError("Invalid length.");
  }
  for (int i = 0; i < inputSummaries.length; i++) {
    Uri inputSummary = inputSummaries[i];
    WorkerInputComponent cachedInput = workerInputCache[inputSummary];
    var digest = workerInputDigests[inputSummary];
    if (digest == null) {
      throw new StateError("Expected to get digest for $inputSummary");
    }
    if (cachedInput == null ||
        cachedInput.component.root != nameRoot ||
        !digestsEqual(digest, cachedInput.digest)) {
      loadFromDillIndexes.add(i);
    } else {
      // Need to reset cached components so they are usable again.
      var component = cachedInput.component;
      for (var lib in component.libraries) {
        lib.isExternal = cachedInput.externalLibs.contains(lib.importUri);
      }
      component.computeCanonicalNames();
      doneInputSummaries[i] = component;
    }
  }

  for (int i = 0; i < loadFromDillIndexes.length; i++) {
    int index = loadFromDillIndexes[i];
    Uri summary = inputSummaries[index];
    List<int> digest = workerInputDigests[summary];
    if (digest == null) {
      throw new StateError("Expected to get digest for $summary");
    }
    var bytes = await fileSystem.entityForUri(summary).readAsBytes();
    WorkerInputComponent cachedInput = WorkerInputComponent(
        digest,
        await compilerState.processedOpts
            .loadComponent(bytes, nameRoot, alwaysCreateNewNamedNodes: true));
    workerInputCache[summary] = cachedInput;
    doneInputSummaries[index] = cachedInput.component;
  }

  incrementalCompiler.setModulesToLoadOnNextComputeDelta(doneInputSummaries);

  return new InitializedCompilerState(options, processedOpts,
      workerInputCache: workerInputCache,
      incrementalCompiler: incrementalCompiler);
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
