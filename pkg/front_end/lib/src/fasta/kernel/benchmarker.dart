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
  BenchmarkSubdivides? _subdivide;

  void beginSubdivide(final BenchmarkSubdivides phase) {
    BenchmarkSubdivides? subdivide = _subdivide;
    if (subdivide != null) throw "Can't subdivide a subdivide";
    _subdivideStopwatch.reset();
    _subdivide = phase;
  }

  void endSubdivide() {
    BenchmarkSubdivides? subdivide = _subdivide;
    if (subdivide == null) throw "Can't end a nonexistent subdivide";
    _phaseTimings[_currentPhase.index]
        .subdivides[subdivide.index]
        .addRuntime(_subdivideStopwatch.elapsedMicroseconds);
    _subdivide = null;
  }

  void enterPhase(BenchmarkPhases phase) {
    if (_currentPhase == phase) return;
    if (_subdivide != null) throw "Can't enter a phase while in a subdivide";

    _phaseTimings[_currentPhase.index]
        .addRuntime(_phaseStopwatch.elapsedMicroseconds);
    _phaseStopwatch.reset();
    _currentPhase = phase;
  }

  void stop() {
    enterPhase(BenchmarkPhases.end);
    _totalStopwatch.stop();
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
    List<SubdivideTiming> enteredSubdivides =
        subdivides.where((element) => element._count > 0).toList();
    return <String, Object?>{
      "phase": phase.name,
      "runtime": _runtime,
      if (enteredSubdivides.isNotEmpty) "subdivides": enteredSubdivides,
    };
  }
}

class SubdivideTiming {
  final BenchmarkSubdivides phase;
  int _runtime = 0;
  int _count = 0;

  SubdivideTiming(this.phase);

  void addRuntime(int runtime) {
    _runtime += runtime;
    _count++;
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
  benchmarkAstVisit,
  // add more here
  //
  end,
  unknown,
}

enum BenchmarkSubdivides {
  tokenize,

  body_buildBody_benchmark_specific_diet_parser,
  body_buildBody_benchmark_specific_parser,

  inferConstructorParameterTypes,
  inferDeclarationType,
  inferExpression,
  inferFieldInitializer,
  inferFunctionBody,
  inferInitializer,
  inferMetadata,
  inferMetadataKeepingHelper,
  inferParameterInitializer,
  inferInvocation,

  buildOutlineExpressions,
  delayedActionPerformer,
}
