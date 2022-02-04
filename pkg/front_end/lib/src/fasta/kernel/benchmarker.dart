// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Benchmarker {
  final Stopwatch _totalStopwatch = new Stopwatch()..start();
  final Stopwatch _phaseStopwatch = new Stopwatch()..start();
  BenchmarkPhases _currentPhase = BenchmarkPhases.implicitInitialization;
  List<PhaseTiming> _phaseTimings = [];

  void enterPhase(BenchmarkPhases phase) {
    if (_currentPhase == phase) return;
    _phaseTimings.add(
        new PhaseTiming(_currentPhase, _phaseStopwatch.elapsedMicroseconds));
    _phaseStopwatch.reset();
    _currentPhase = phase;
  }

  void stop() {
    enterPhase(BenchmarkPhases.end);
    _totalStopwatch.stop();
  }

  Map<String, Object?> toJson() {
    // TODO: Merge unknown?
    return <String, Object?>{
      "totalTime": _totalStopwatch.elapsedMicroseconds,
      "phases": _phaseTimings,
    };
  }
}

class PhaseTiming {
  final BenchmarkPhases phase;
  final int runtime;

  PhaseTiming(this.phase, this.runtime);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      "phase": phase.name,
      "runtime": runtime,
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
  outline_buildClassHierarchyMembers,
  outline_computeHierarchy,
  outline_computeShowHideElements,
  outline_installTypedefTearOffs,
  outline_performTopLevelInference,
  outline_checkOverrides,
  outline_checkAbstractMembers,
  outline_addNoSuchMethodForwarders,
  outline_checkMixins,
  outline_buildOutlineExpressions,
  outline_checkTypes,
  outline_checkRedirectingFactories,
  outline_finishSynthesizedParameters,
  outline_checkMainMethods,
  outline_installAllComponentProblems,

  body_buildBodies,
  body_finishSynthesizedParameters,

  body_finishDeferredLoadTearoffs,
  body_finishNoSuchMethodForwarders,
  body_collectSourceClasses,
  body_applyDefinitionMacros,
  body_finishNativeMethods,
  body_finishPatchMethods,
  body_finishAllConstructors,
  body_runBuildTransformations,
  body_verify,
  body_installAllComponentProblems,

  printComponentText,
  omitPlatform,
  writeComponent,
  // add more here
  //
  end,
  unknown,
}
