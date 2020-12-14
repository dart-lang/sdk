// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart' show Component, CanonicalName, Library;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/nnbd_mode.dart' show NnbdMode;

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
/// * [outputLoadedAdditionalDills] should be given as an empty list of the same
///   size as the [additionalDills]. The input summaries are loaded (or taken
///   from cache) and placed in this list in order, i.e. the `i`-th entry in
///   [outputLoadedAdditionalDills] after this call corresponds to the component
///   loaded from the `i`-th entry in [additionalDills].
Future<InitializedCompilerState> initializeIncrementalCompiler(
    InitializedCompilerState oldState,
    Set<String> tags,
    List<Component> outputLoadedAdditionalDills,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> additionalDills,
    Map<Uri, List<int>> workerInputDigests,
    Target target,
    {bool compileSdk: false,
    Uri sdkRoot: null,
    FileSystem fileSystem,
    Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    Map<String, String> environmentDefines: const {},
    bool outlineOnly,
    bool omitPlatform: false,
    bool trackNeededDillLibraries: false,
    bool verbose: false,
    NnbdMode nnbdMode: NnbdMode.Weak}) async {
  bool isRetry = false;
  while (true) {
    try {
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
          oldState.options.nnbdMode != nnbdMode ||
          !equalMaps(oldState.options.explicitExperimentalFlags,
              explicitExperimentalFlags) ||
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
          ..explicitExperimentalFlags = explicitExperimentalFlags
          ..verbose = verbose
          ..nnbdMode = nnbdMode;

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

        // Make sure the canonical name root knows about the sdk - otherwise we
        // won't be able to link to it when loading more outlines.
        sdkComponent.adoptChildren();

        // TODO(jensj): This is - at least currently - necessary,
        // although it's not entirely obvious why.
        // It likely has to do with several outlines containing the same
        // libraries. Once that stops (and we check for it) we can probably
        // remove this, and instead only do it when about to reuse a component
        // further down.
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
      List<int> loadFromDillIndexes = <int>[];

      // Notice that the ordering of the input summaries matter, so we need to
      // keep them in order.
      if (outputLoadedAdditionalDills.length != additionalDills.length) {
        throw new ArgumentError("Invalid length.");
      }
      Set<Uri> additionalDillsSet = new Set<Uri>();
      for (int i = 0; i < additionalDills.length; i++) {
        Uri summaryUri = additionalDills[i];
        additionalDillsSet.add(summaryUri);
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
          if (trackNeededDillLibraries) {
            for (Library lib in component.libraries) {
              libraryToInputDill[lib.importUri] = summaryUri;
            }
          }
          component.computeCanonicalNames(); // this isn't needed, is it?
          outputLoadedAdditionalDills[i] = component;
        }
      }

      for (int i = 0; i < loadFromDillIndexes.length; i++) {
        int index = loadFromDillIndexes[i];
        Uri additionalDillUri = additionalDills[index];
        List<int> digest = workerInputDigests[additionalDillUri];
        if (digest == null) {
          throw new StateError("Expected to get digest for $additionalDillUri");
        }

        List<int> bytes =
            await fileSystem.entityForUri(additionalDillUri).readAsBytes();
        WorkerInputComponent cachedInput = new WorkerInputComponent(
            digest,
            await processedOpts.loadComponent(bytes, nameRoot,
                alwaysCreateNewNamedNodes: true));
        workerInputCache[additionalDillUri] = cachedInput;
        outputLoadedAdditionalDills[index] = cachedInput.component;
        for (Library lib in cachedInput.component.libraries) {
          if (workerInputCacheLibs.containsKey(lib.importUri)) {
            Uri fromSummary = workerInputCacheLibs[lib.importUri];
            if (additionalDillsSet.contains(fromSummary)) {
              throw new StateError(
                  "Asked to load several summaries that contain the same "
                  "library.");
            } else {
              // Library contained in old cached component. Flush that cache.
              Component component =
                  workerInputCache.remove(fromSummary).component;
              for (Library lib in component.libraries) {
                workerInputCacheLibs.remove(lib.importUri);
              }
            }
          } else {
            workerInputCacheLibs[lib.importUri] = additionalDillUri;
          }

          if (trackNeededDillLibraries) {
            libraryToInputDill[lib.importUri] = additionalDillUri;
          }
        }
      }

      incrementalCompiler
          .setModulesToLoadOnNextComputeDelta(outputLoadedAdditionalDills);

      return new InitializedCompilerState(options, processedOpts,
          workerInputCache: workerInputCache,
          workerInputCacheLibs: workerInputCacheLibs,
          incrementalCompiler: incrementalCompiler,
          tags: tags,
          libraryToInputDill: libraryToInputDill);
    } catch (e, s) {
      if (isRetry) rethrow;
      print('''
Failed to initialize incremental compiler, throwing away old state.

This is likely a result of https://github.com/dart-lang/sdk/issues/38102, if
you are consistently seeing this problem please see that issue.

The specific exception that was encountered was:

$e
$s
''');
      isRetry = true;
      oldState = null;
      // Artificial delay to attempt to increase the odds of recovery from
      // timing related issues.
      await new Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
