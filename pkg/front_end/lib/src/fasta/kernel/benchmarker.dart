// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Benchmarker {
  final List<PhaseTiming> _phaseTimings =
      new List<PhaseTiming>.generate(BenchmarkPhases.values.length, (index) {
    assert(BenchmarkPhases.values[index].index == index);
    return new PhaseTiming(BenchmarkPhases.values[index]);
  }, growable: false);

  final Stopwatch _totalStopwatch = new Stopwatch()..start();
  final Stopwatch _phaseStopwatch = new Stopwatch()..start();
  final Stopwatch _subdivideStopwatch = new Stopwatch()..start();

  BenchmarkPhases _currentPhase = BenchmarkPhases.implicitInitialization;
  List<BenchmarkSubdivides> _subdivides = [
    BenchmarkSubdivides.subdividesUnaccountedFor
  ];

  void reset() {
    _totalStopwatch.start();
    _totalStopwatch.reset();
    _phaseStopwatch.start();
    _phaseStopwatch.reset();
    _subdivideStopwatch.start();
    _subdivideStopwatch.reset();
    for (int i = 0; i < _phaseTimings.length; i++) {
      assert(BenchmarkPhases.values[i].index == i);
      _phaseTimings[i] = new PhaseTiming(BenchmarkPhases.values[i]);
    }
    _subdivides = [BenchmarkSubdivides.subdividesUnaccountedFor];
    _currentPhase = BenchmarkPhases.implicitInitialization;
  }

  void beginSubdivide(final BenchmarkSubdivides phase) {
    _pauseLatestSubdivide(addAsCount: false);
    _subdivideStopwatch.reset();
    _subdivides.add(phase);
  }

  void _pauseLatestSubdivide({required bool addAsCount}) {
    if (_subdivides.isEmpty) return;
    BenchmarkSubdivides subdivide = _subdivides.last;
    _phaseTimings[_currentPhase.index].subdivides[subdivide.index].addRuntime(
        _subdivideStopwatch.elapsedMicroseconds,
        addAsCount: addAsCount);
  }

  void endSubdivide() {
    if (_subdivides.isEmpty) throw "Can't end a nonexistent subdivide";
    _pauseLatestSubdivide(addAsCount: true);
    _subdivides.removeLast();
    _subdivideStopwatch.reset();
  }

  void enterPhase(BenchmarkPhases phase) {
    if (_currentPhase == phase) return;
    if (_subdivides.isEmpty) {
      throw "System subdivide removed.";
    }
    endSubdivide();
    if (_subdivides.isNotEmpty) {
      throw "Can't enter a phase while in a subdivide";
    }

    _phaseTimings[_currentPhase.index]
        .addRuntime(_phaseStopwatch.elapsedMicroseconds);
    _phaseStopwatch.reset();
    _currentPhase = phase;
    beginSubdivide(BenchmarkSubdivides.subdividesUnaccountedFor);
  }

  void stop() {
    enterPhase(BenchmarkPhases.end);
    _totalStopwatch.stop();
    if (_subdivides.isEmpty) {
      throw "System subdivide removed.";
    }
    endSubdivide();
    if (_subdivides.isNotEmpty) {
      throw "Can't stop while in a subdivide";
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "totalTime": _totalStopwatch.elapsedMicroseconds,
      "phases": _phaseTimings,
    };
  }
}

class PhaseTiming {
  final BenchmarkPhases phase;
  int _runtime = 0;

  final List<SubdivideTiming> subdivides = new List<SubdivideTiming>.generate(
      BenchmarkSubdivides.values.length, (index) {
    assert(BenchmarkSubdivides.values[index].index == index);
    return new SubdivideTiming(BenchmarkSubdivides.values[index]);
  }, growable: false);

  PhaseTiming(this.phase);

  void addRuntime(int runtime) {
    _runtime += runtime;
  }

  Map<String, Object?> toJson() {
    List<SubdivideTiming> enteredSubdivides = [];
    int subdivideRuntime = 0;
    for (SubdivideTiming subdivide in subdivides) {
      if (subdivide._count > 0) {
        enteredSubdivides.add(subdivide);
        subdivideRuntime += subdivide._runtime;
      }
    }
    return <String, Object?>{
      "phase": phase.name,
      "runtime": _runtime,
      "subdivides": enteredSubdivides,
      "estimatedSubdividesOverhead": _runtime - subdivideRuntime,
    };
  }
}

class SubdivideTiming {
  final BenchmarkSubdivides phase;
  int _runtime = 0;
  int _count = 0;

  SubdivideTiming(this.phase);

  void addRuntime(int runtime, {required bool addAsCount}) {
    _runtime += runtime;
    if (addAsCount) {
      _count++;
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "phase": phase.name,
      "runtime": _runtime,
      "count": _count,
    };
  }
}

enum BenchmarkPhases {
  implicitInitialization,
  loadSDK,
  loadAdditionalDills,

  dill_buildOutlines,
  dill_finalizeExports,

  outline_kernelBuildOutlines,
  outline_becomeCoreLibrary,
  outline_resolveParts,
  outline_computeMacroDeclarations,
  outline_computeLibraryScopes,
  outline_computeMacroApplications,
  outline_setupTopAndBottomTypes,
  outline_resolveTypes,
  outline_computeVariances,
  outline_computeDefaultTypes,
  outline_applyTypeMacros,
  outline_buildMacroTypesForPhase1,
  outline_checkSemantics,
  outline_finishTypeVariables,
  outline_createTypeInferenceEngine,
  outline_buildComponent,
  outline_installDefaultSupertypes,
  outline_installSyntheticConstructors,
  outline_resolveConstructors,
  outline_link,
  outline_computeCoreTypes,
  outline_buildClassHierarchy,
  outline_checkSupertypes,
  outline_applyDeclarationMacros,
  outline_buildMacroDeclarationsForPhase1,
  outline_buildMacroDeclarationsForPhase2,
  outline_buildClassHierarchyMembers,
  outline_computeHierarchy,
  outline_computeShowHideElements,
  outline_installTypedefTearOffs,
  outline_performTopLevelInference,
  outline_checkOverrides,
  outline_checkAbstractMembers,
  outline_computeFieldPromotability,
  outline_checkMixins,
  outline_buildOutlineExpressions,
  outline_checkTypes,
  outline_checkRedirectingFactories,
  outline_finishSynthesizedParameters,
  outline_checkMainMethods,
  outline_installAllComponentProblems,

  body_buildBodies,
  body_checkMixinSuperAccesses,
  body_finishSynthesizedParameters,
  body_finishDeferredLoadTearoffs,
  body_finishNoSuchMethodForwarders,
  body_collectSourceClasses,
  body_applyDefinitionMacros,
  body_buildMacroDefinitionsForPhase1,
  body_buildMacroDefinitionsForPhase2,
  body_buildMacroDefinitionsForPhase3,
  body_finishNativeMethods,
  body_finishPatchMethods,
  body_finishAllConstructors,
  body_runBuildTransformations,
  body_verify,
  body_installAllComponentProblems,

  printComponentText,
  omitPlatform,
  writeComponent,
  benchmarkAstVisit,

  incremental_setupPackages,
  incremental_ensurePlatform,
  incremental_invalidate,
  incremental_experimentalInvalidation,
  incremental_rewriteEntryPointsIfPart,
  incremental_invalidatePrecompiledMacros,
  incremental_cleanup,
  incremental_loadEnsureLoadedComponents,
  incremental_setupInLoop,
  incremental_precompileMacros,
  incremental_experimentalInvalidationPatchUpScopes,
  incremental_hierarchy,
  incremental_performDillUsageTracking,
  incremental_releaseAncillaryResources,
  incremental_experimentalCompilationPostCompilePatchup,
  incremental_calculateOutputLibrariesAndIssueLibraryProblems,
  incremental_convertSourceLibraryBuildersToDill,
  incremental_end,

  precompileMacros,

  // add more here
  //
  end,
  unknown,
  unknownDillTarget,
  unknownComputeNeededPrecompilations,
  unknownBuildOutlines,
  unknownBuildComponent,
  unknownGenerateKernelInternal,
}

enum BenchmarkSubdivides {
  subdividesUnaccountedFor,

  tokenize,

  body_buildBody_benchmark_specific_diet_parser,
  body_buildBody_benchmark_specific_parser,

  diet_listener_createListener,
  diet_listener_buildFields,
  diet_listener_buildFunctionBody,
  diet_listener_buildFunctionBody_parseFunctionBody,
  diet_listener_buildRedirectingFactoryMethod,

  inferImplicitFieldType,
  inferFieldInitializer,
  inferFunctionBody,
  inferInitializer,
  inferMetadata,
  inferParameterInitializer,
  inferRedirectingFactoryTypeArguments,

  buildOutlineExpressions,
  delayedActionPerformer,

  computeMacroApplications_macroExecutorProvider,
  macroApplications_macroExecutorLoadMacro,
  macroApplications_macroExecutorInstantiateMacro,
}
