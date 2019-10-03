// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Component, CanonicalName, Library;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/incremental_compiler.dart' show IncrementalCompiler;

import 'compiler_state.dart'
    show InitializedCompilerState, WorkerInputComponent, digestsEqual;

import 'util.dart' show equalMaps, equalSets;

/// Initializes the compiler for a modular build.
///
/// Re-uses cached components from [oldState.workerInputCache], and reloads them
/// as necessary based on [workerInputDigests].
///
/// Notes:
/// * [outputLoadedInputSummaries] should be given as an empty list of the same
///   size as the [inputSummaries]. The input summaries are loaded (or taken
///   from cache) and placed in this list in order, i.e. the `i`-th entry in
///   [outputLoadedInputSummaries] after this call corresponds to the component
///   loaded from the `i`-th entry in [inputSummaries].
Future<InitializedCompilerState> initializeIncrementalCompiler(
    InitializedCompilerState oldState,
    Set<String> tags,
    List<Component> outputLoadedInputSummaries,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> inputSummaries,
    Map<Uri, List<int>> workerInputDigests,
    Target target,
    {bool compileSdk: false,
    Uri sdkRoot: null,
    FileSystem fileSystem,
    Map<ExperimentalFlag, bool> experimentalFlags,
    Map<String, String> environmentDefines: const {},
    bool outlineOnly,
    bool omitPlatform: false,
    bool trackNeededDillLibraries: false}) async {
  final List<int> sdkDigest = workerInputDigests[sdkSummary];
  if (sdkDigest == null) {
    throw new StateError("Expected to get digest for $sdkSummary");
  }

  Map<Uri, WorkerInputComponent> workerInputCache =
      oldState?.workerInputCache ?? new Map<Uri, WorkerInputComponent>();
  Map<Uri, Uri> workerInputCacheLibs =
      oldState?.workerInputCacheLibs ?? new Map<Uri, Uri>();

  WorkerInputComponent cachedSdkInput = workerInputCache[sdkSummary];

  IncrementalCompiler incrementalCompiler;
  CompilerOptions options;
  ProcessedOptions processedOpts;

  if (oldState == null ||
      oldState.incrementalCompiler == null ||
      oldState.options.compileSdk != compileSdk ||
      oldState.incrementalCompiler.outlineOnly != outlineOnly ||
      !equalMaps(oldState.options.experimentalFlags, experimentalFlags) ||
      !equalMaps(oldState.options.environmentDefines, environmentDefines) ||
      !equalSets(oldState.tags, tags) ||
      cachedSdkInput == null ||
      !digestsEqual(cachedSdkInput.digest, sdkDigest)) {
    // No - or immediately not correct - previous state.
    // We'll load a new sdk, anything loaded already will have a wrong root.
    workerInputCache.clear();
    workerInputCacheLibs.clear();

    // The sdk was either not cached or it has changed.
    options = new CompilerOptions()
      ..compileSdk = compileSdk
      ..sdkRoot = sdkRoot
      ..sdkSummary = sdkSummary
      ..packagesFileUri = packagesFile
      ..librariesSpecificationUri = librariesSpecificationUri
      ..target = target
      ..fileSystem = fileSystem
      ..omitPlatform = omitPlatform
      ..environmentDefines = environmentDefines
      ..experimentalFlags = experimentalFlags;

    processedOpts = new ProcessedOptions(options: options);
    cachedSdkInput = new WorkerInputComponent(
        sdkDigest, await processedOpts.loadSdkSummary(null));
    workerInputCache[sdkSummary] = cachedSdkInput;
    for (Library lib in cachedSdkInput.component.libraries) {
      if (workerInputCacheLibs.containsKey(lib.importUri)) {
        throw new StateError("Duplicate sources in sdk.");
      }
      workerInputCacheLibs[lib.importUri] = sdkSummary;
    }

    incrementalCompiler = new IncrementalCompiler.fromComponent(
        new CompilerContext(processedOpts),
        cachedSdkInput.component,
        outlineOnly);
    incrementalCompiler.trackNeededDillLibraries = trackNeededDillLibraries;
  } else {
    options = oldState.options;
    processedOpts = oldState.processedOpts;
    Component sdkComponent = cachedSdkInput.component;
    // Reset the state of the component.
    for (Library lib in sdkComponent.libraries) {
      lib.isExternal = cachedSdkInput.externalLibs.contains(lib.importUri);
    }

    // Make sure the canonical name root knows about the sdk - otherwise we
    // won't be able to link to it when loading more outlines.
    sdkComponent.adoptChildren();

    // TODO(jensj): This is - at least currently - necessary,
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
    incrementalCompiler.trackNeededDillLibraries = trackNeededDillLibraries;
    options.packagesFileUri = packagesFile;
    options.fileSystem = fileSystem;
    processedOpts.clearFileSystemCache();
  }

  // Then read all the input summary components.
  CanonicalName nameRoot = cachedSdkInput.component.root;
  Map<Uri, Uri> libraryToInputDill;
  if (trackNeededDillLibraries) {
    libraryToInputDill = new Map<Uri, Uri>();
  }
  List<int> loadFromDillIndexes = new List<int>();

  // Notice that the ordering of the input summaries matter, so we need to
  // keep them in order.
  if (outputLoadedInputSummaries.length != inputSummaries.length) {
    throw new ArgumentError("Invalid length.");
  }
  Set<Uri> inputSummariesSet = new Set<Uri>();
  for (int i = 0; i < inputSummaries.length; i++) {
    Uri summaryUri = inputSummaries[i];
    inputSummariesSet.add(summaryUri);
    WorkerInputComponent cachedInput = workerInputCache[summaryUri];
    List<int> digest = workerInputDigests[summaryUri];
    if (digest == null) {
      throw new StateError("Expected to get digest for $summaryUri");
    }
    if (cachedInput == null ||
        cachedInput.component.root != nameRoot ||
        !digestsEqual(digest, cachedInput.digest)) {
      // Remove any old libraries from workerInputCacheLibs.
      Component component = cachedInput?.component;
      if (component != null) {
        for (Library lib in component.libraries) {
          workerInputCacheLibs.remove(lib.importUri);
        }
      }

      loadFromDillIndexes.add(i);
    } else {
      // Need to reset cached components so they are usable again.
      Component component = cachedInput.component;
      for (Library lib in component.libraries) {
        lib.isExternal = cachedInput.externalLibs.contains(lib.importUri);
        if (trackNeededDillLibraries) {
          libraryToInputDill[lib.importUri] = summaryUri;
        }
      }
      component.computeCanonicalNames(); // this isn't needed, is it?
      outputLoadedInputSummaries[i] = component;
    }
  }

  for (int i = 0; i < loadFromDillIndexes.length; i++) {
    int index = loadFromDillIndexes[i];
    Uri summaryUri = inputSummaries[index];
    List<int> digest = workerInputDigests[summaryUri];
    if (digest == null) {
      throw new StateError("Expected to get digest for $summaryUri");
    }

    List<int> bytes = await fileSystem.entityForUri(summaryUri).readAsBytes();
    WorkerInputComponent cachedInput = new WorkerInputComponent(
        digest,
        await processedOpts.loadComponent(bytes, nameRoot,
            alwaysCreateNewNamedNodes: true));
    workerInputCache[summaryUri] = cachedInput;
    outputLoadedInputSummaries[index] = cachedInput.component;
    for (Library lib in cachedInput.component.libraries) {
      if (workerInputCacheLibs.containsKey(lib.importUri)) {
        Uri fromSummary = workerInputCacheLibs[lib.importUri];
        if (inputSummariesSet.contains(fromSummary)) {
          throw new StateError(
              "Asked to load several summaries that contain the same library.");
        } else {
          // Library contained in old cached component. Flush that cache.
          Component component = workerInputCache.remove(fromSummary).component;
          for (Library lib in component.libraries) {
            workerInputCacheLibs.remove(lib.importUri);
          }
        }
      } else {
        workerInputCacheLibs[lib.importUri] = summaryUri;
      }

      if (trackNeededDillLibraries) {
        libraryToInputDill[lib.importUri] = summaryUri;
      }
    }
  }

  incrementalCompiler
      .setModulesToLoadOnNextComputeDelta(outputLoadedInputSummaries);

  return new InitializedCompilerState(options, processedOpts,
      workerInputCache: workerInputCache,
      workerInputCacheLibs: workerInputCacheLibs,
      incrementalCompiler: incrementalCompiler,
      tags: tags,
      libraryToInputDill: libraryToInputDill);
}
