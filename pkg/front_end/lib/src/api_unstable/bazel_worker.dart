// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API needed by `utils/front_end/summary_worker.dart`, a tool used to compute
/// summaries in build systems like bazel, pub-build, and package-build.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Component, CanonicalName;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags;

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessageHandler;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/incremental_compiler.dart' show IncrementalCompiler;

import '../kernel_generator_impl.dart' show CompilerResult, generateKernel;

import 'compiler_state.dart'
    show InitializedCompilerState, WorkerInputComponent, digestsEqual;

export '../api_prototype/diagnostic_message.dart' show DiagnosticMessage;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../fasta/kernel/utils.dart' show serializeComponent;

export '../fasta/severity.dart' show Severity;

export 'compiler_state.dart' show InitializedCompilerState;

import 'util.dart' show equalMaps;

/// Initializes the compiler for a modular build.
///
/// Re-uses cached components from [_workerInputCache], and reloads them
/// as necessary based on [workerInputDigests].
Future<InitializedCompilerState> initializeIncrementalCompiler(
    InitializedCompilerState oldState,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> summaryInputs,
    Map<Uri, List<int>> workerInputDigests,
    Target target,
    FileSystem fileSystem,
    Iterable<String> experiments,
    bool outlineOnly) async {
  final List<int> sdkDigest = workerInputDigests[sdkSummary];
  if (sdkDigest == null) {
    throw new StateError("Expected to get digest for $sdkSummary");
  }
  IncrementalCompiler incrementalCompiler;
  CompilerOptions options;
  ProcessedOptions processedOpts;
  WorkerInputComponent cachedSdkInput;
  Map<Uri, WorkerInputComponent> workerInputCache =
      oldState?.workerInputCache ?? new Map<Uri, WorkerInputComponent>();
  bool startOver = false;
  Map<ExperimentalFlag, bool> experimentalFlags =
      parseExperimentalFlags(experiments, (e) => throw e);

  if (oldState == null ||
      oldState.incrementalCompiler == null ||
      oldState.incrementalCompiler.outlineOnly != outlineOnly ||
      !equalMaps(oldState.options.experimentalFlags, experimentalFlags)) {
    // No - or immediately not correct - previous state.
    startOver = true;

    // We'll load a new sdk, anything loaded already will have a wrong root.
    workerInputCache.clear();
  } else {
    // We do have a previous state.
    cachedSdkInput = workerInputCache[sdkSummary];
    if (cachedSdkInput == null ||
        !digestsEqual(cachedSdkInput.digest, sdkDigest)) {
      // The sdk is out of date.
      startOver = true;
      // We'll load a new sdk, anything loaded already will have a wrong root.
      workerInputCache.clear();
    }
  }

  if (startOver) {
    // The sdk was either not cached or it has changed.
    options = new CompilerOptions()
      ..sdkSummary = sdkSummary
      ..packagesFileUri = packagesFile
      ..librariesSpecificationUri = librariesSpecificationUri
      ..target = target
      ..fileSystem = fileSystem
      ..omitPlatform = true
      ..environmentDefines = const {}
      ..experimentalFlags = experimentalFlags;

    processedOpts = new ProcessedOptions(options: options);
    cachedSdkInput = WorkerInputComponent(
        sdkDigest, await processedOpts.loadSdkSummary(null));
    workerInputCache[sdkSummary] = cachedSdkInput;

    incrementalCompiler = new IncrementalCompiler.fromComponent(
        new CompilerContext(processedOpts),
        cachedSdkInput.component,
        outlineOnly);
  } else {
    options = oldState.options;
    processedOpts = oldState.processedOpts;
    var sdkComponent = cachedSdkInput.component;
    // Reset the state of the component.
    for (var lib in sdkComponent.libraries) {
      lib.isExternal = cachedSdkInput.externalLibs.contains(lib.importUri);
    }

    // Make sure the canonical name root knows about the sdk - otherwise we
    // won't be able to link to it when loading more outlines.
    sdkComponent.adoptChildren();

    // TODO(jensj): This is - at least currently - neccessary,
    // although it's not entirely obvious why.
    // It likely has to do with several outlines containing the same libraries.
    // Once that stops (and we check for it) we can probably remove this,
    // and instead only do it when about to reuse an outline in the
    // 'inputSummaries.add(component);' line further down.
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

  // Then read all the input summary components.
  CanonicalName nameRoot = cachedSdkInput.component.root;
  final inputSummaries = <Component>[];
  List<Uri> loadFromDill = new List<Uri>();
  for (Uri summary in summaryInputs) {
    var cachedInput = workerInputCache[summary];
    var summaryDigest = workerInputDigests[summary];
    if (summaryDigest == null) {
      throw new StateError("Expected to get digest for $summary");
    }
    if (cachedInput == null ||
        cachedInput.component.root != nameRoot ||
        !digestsEqual(cachedInput.digest, summaryDigest)) {
      loadFromDill.add(summary);
    } else {
      // Need to reset cached components so they are usable again.
      var component = cachedInput.component;
      for (var lib in component.libraries) {
        lib.isExternal = cachedInput.externalLibs.contains(lib.importUri);
      }
      inputSummaries.add(component);
    }
  }

  for (int i = 0; i < loadFromDill.length; i++) {
    Uri summary = loadFromDill[i];
    List<int> summaryDigest = workerInputDigests[summary];
    if (summaryDigest == null) {
      throw new StateError("Expected to get digest for $summary");
    }
    WorkerInputComponent cachedInput = WorkerInputComponent(
        summaryDigest,
        await processedOpts.loadComponent(
            await fileSystem.entityForUri(summary).readAsBytes(), nameRoot,
            alwaysCreateNewNamedNodes: true));
    workerInputCache[summary] = cachedInput;
    inputSummaries.add(cachedInput.component);
  }

  incrementalCompiler.setModulesToLoadOnNextComputeDelta(inputSummaries);

  return new InitializedCompilerState(options, processedOpts,
      workerInputCache: workerInputCache,
      incrementalCompiler: incrementalCompiler);
}

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    Uri sdkSummary,
    Uri librariesSpecificationUri,
    Uri packagesFile,
    List<Uri> summaryInputs,
    List<Uri> linkedInputs,
    Target target,
    FileSystem fileSystem,
    Iterable<String> experiments) async {
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
    ..fileSystem = fileSystem
    ..environmentDefines = const {}
    ..experimentalFlags = parseExperimentalFlags(experiments, (e) => throw e);

  ProcessedOptions processedOpts = new ProcessedOptions(options: options);

  return new InitializedCompilerState(options, processedOpts);
}

Future<CompilerResult> _compile(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler,
    {bool summaryOnly, bool includeOffsets: true}) {
  summaryOnly ??= true;
  CompilerOptions options = compilerState.options;
  options..onDiagnostic = diagnosticMessageHandler;

  ProcessedOptions processedOpts = compilerState.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);

  return generateKernel(processedOpts,
      buildSummary: summaryOnly,
      buildComponent: !summaryOnly,
      includeOffsets: includeOffsets);
}

Future<List<int>> compileSummary(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler,
    {bool includeOffsets: false}) async {
  var result = await _compile(compilerState, inputs, diagnosticMessageHandler,
      summaryOnly: true, includeOffsets: includeOffsets);
  return result?.summary;
}

Future<Component> compileComponent(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler) async {
  var result = await _compile(compilerState, inputs, diagnosticMessageHandler,
      summaryOnly: false);

  var component = result?.component;
  if (component != null) {
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
  return component;
}
