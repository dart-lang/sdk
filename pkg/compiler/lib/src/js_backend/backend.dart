// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import '../common.dart';
import '../common/codegen.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../dump_info.dart' show DumpInfoTask;
import '../elements/entities.dart';
import '../enqueue.dart' show ResolutionEnqueuer;
import '../frontend_strategy.dart';
import '../inferrer/types.dart';
import '../js_model/elements.dart';
import '../tracer.dart';
import '../universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
import 'annotations.dart';
import 'checked_mode_helpers.dart';
import 'namer.dart';
import 'runtime_types_codegen.dart';
import 'runtime_types_new.dart';

abstract class FunctionCompiler {
  void initialize(
      GlobalTypeInferenceResults globalInferenceResults, CodegenInputs codegen);

  /// Generates JavaScript code for [member].
  CodegenResult compile(MemberEntity member);

  Iterable get tasks;
}

/*
 * Invariants:
 *   canInline(function) implies canInline(function, insideLoop:true)
 *   !canInline(function, insideLoop: true) implies !canInline(function)
 */
class FunctionInlineCache {
  static const int _unknown = -1;
  static const int _mustNotInline = 0;
  // May-inline-in-loop means that the function may not be inlined outside loops
  // but may be inlined in a loop.
  static const int _mayInlineInLoopMustNotOutside = 1;
  // The function can be inlined in a loop, but not outside.
  static const int _canInlineInLoopMustNotOutside = 2;
  // May-inline means that we know that it can be inlined inside a loop, but
  // don't know about the general case yet.
  static const int _canInlineInLoopMayInlineOutside = 3;
  static const int _canInline = 4;

  final Map<FunctionEntity, int> _cachedDecisions =
      new Map<FunctionEntity, int>();

  final Set<FunctionEntity> _noInlineFunctions = new Set<FunctionEntity>();
  final Set<FunctionEntity> _tryInlineFunctions = new Set<FunctionEntity>();

  FunctionInlineCache(AnnotationsData annotationsData) {
    annotationsData.forEachNoInline((FunctionEntity function) {
      markAsNoInline(function);
    });
    annotationsData.forEachTryInline((FunctionEntity function) {
      markAsTryInline(function);
    });
  }

  /// Checks that [method] is the canonical representative for this method.
  ///
  /// For a [MethodElement] this means it must be the declaration element.
  bool checkFunction(FunctionEntity method) {
    return '$method'.startsWith(jsElementPrefix);
  }

  /// Returns the current cache decision. This should only be used for testing.
  int getCurrentCacheDecisionForTesting(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    return _cachedDecisions[element];
  }

  // Returns `true`/`false` if we have a cached decision.
  // Returns `null` otherwise.
  bool canInline(FunctionEntity element, {bool insideLoop}) {
    assert(checkFunction(element), failedAt(element));
    int decision = _cachedDecisions[element];

    if (decision == null) {
      // TODO(sra): Have annotations for mustInline / noInline for constructor
      // bodies. (There used to be some logic here to have constructor bodies,
      // inherit the settings from annotations on the generative
      // constructor. This was conflated with the heuristic decisions, leading
      // to lack of inlining where it was beneficial.)
      decision = _unknown;
    }

    if (insideLoop) {
      switch (decision) {
        case _mustNotInline:
          return false;

        case _unknown:
        case _mayInlineInLoopMustNotOutside:
          // We know we can't inline outside a loop, but don't know for the
          // loop case. Return `null` to indicate that we don't know yet.
          return null;

        case _canInlineInLoopMustNotOutside:
        case _canInlineInLoopMayInlineOutside:
        case _canInline:
          return true;
      }
    } else {
      switch (decision) {
        case _mustNotInline:
        case _mayInlineInLoopMustNotOutside:
        case _canInlineInLoopMustNotOutside:
          return false;

        case _unknown:
        case _canInlineInLoopMayInlineOutside:
          // We know we can inline inside a loop, but don't know for the
          // non-loop case. Return `null` to indicate that we don't know yet.
          return null;

        case _canInline:
          return true;
      }
    }

    // Quiet static checker.
    return null;
  }

  void markAsInlinable(FunctionEntity element, {bool insideLoop}) {
    assert(checkFunction(element), failedAt(element));
    int oldDecision = _cachedDecisions[element];

    if (oldDecision == null) {
      oldDecision = _unknown;
    }

    if (insideLoop) {
      switch (oldDecision) {
        case _mustNotInline:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _unknown:
          // We know that it can be inlined in a loop, but don't know about the
          // non-loop case yet.
          _cachedDecisions[element] = _canInlineInLoopMayInlineOutside;
          break;

        case _mayInlineInLoopMustNotOutside:
          _cachedDecisions[element] = _canInlineInLoopMustNotOutside;
          break;

        case _canInlineInLoopMustNotOutside:
        case _canInlineInLoopMayInlineOutside:
        case _canInline:
          // Do nothing.
          break;
      }
    } else {
      switch (oldDecision) {
        case _mustNotInline:
        case _mayInlineInLoopMustNotOutside:
        case _canInlineInLoopMustNotOutside:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _unknown:
        case _canInlineInLoopMayInlineOutside:
          _cachedDecisions[element] = _canInline;
          break;

        case _canInline:
          // Do nothing.
          break;
      }
    }
  }

  void markAsNonInlinable(FunctionEntity element, {bool insideLoop: true}) {
    assert(checkFunction(element), failedAt(element));
    int oldDecision = _cachedDecisions[element];

    if (oldDecision == null) {
      oldDecision = _unknown;
    }

    if (insideLoop) {
      switch (oldDecision) {
        case _canInlineInLoopMustNotOutside:
        case _canInlineInLoopMayInlineOutside:
        case _canInline:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _mayInlineInLoopMustNotOutside:
        case _unknown:
          _cachedDecisions[element] = _mustNotInline;
          break;

        case _mustNotInline:
          // Do nothing.
          break;
      }
    } else {
      switch (oldDecision) {
        case _canInline:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _unknown:
          // We can't inline outside a loop, but we might still be allowed to do
          // so outside.
          _cachedDecisions[element] = _mayInlineInLoopMustNotOutside;
          break;

        case _canInlineInLoopMayInlineOutside:
          // We already knew that the function could be inlined inside a loop,
          // but didn't have information about the non-loop case. Now we know
          // that it can't be inlined outside a loop.
          _cachedDecisions[element] = _canInlineInLoopMustNotOutside;
          break;

        case _mayInlineInLoopMustNotOutside:
        case _canInlineInLoopMustNotOutside:
        case _mustNotInline:
          // Do nothing.
          break;
      }
    }
  }

  void markAsNoInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    _noInlineFunctions.add(element);
  }

  bool markedAsNoInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    return _noInlineFunctions.contains(element);
  }

  void markAsTryInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    _tryInlineFunctions.add(element);
  }

  bool markedAsTryInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    return _tryInlineFunctions.contains(element);
  }
}

class JavaScriptImpactStrategy extends ImpactStrategy {
  final ImpactCacheDeleter impactCacheDeleter;
  final DumpInfoTask dumpInfoTask;
  final bool supportDeferredLoad;
  final bool supportDumpInfo;

  JavaScriptImpactStrategy(this.impactCacheDeleter, this.dumpInfoTask,
      {this.supportDeferredLoad, this.supportDumpInfo});

  @override
  void visitImpact(var impactSource, WorldImpact impact,
      WorldImpactVisitor visitor, ImpactUseCase impactUse) {
    // TODO(johnniwinther): Compute the application strategy once for each use.
    if (impactUse == ResolutionEnqueuer.IMPACT_USE) {
      if (supportDeferredLoad) {
        impact.apply(visitor);
      } else {
        impact.apply(visitor);
      }
    } else if (impactUse == DeferredLoadTask.IMPACT_USE) {
      impact.apply(visitor);
      // Impacts are uncached globally in [onImpactUsed].
    } else if (impactUse == DumpInfoTask.IMPACT_USE) {
      impact.apply(visitor);
      dumpInfoTask.unregisterImpact(impactSource);
    } else {
      impact.apply(visitor);
    }
  }

  @override
  void onImpactUsed(ImpactUseCase impactUse) {
    if (impactUse == DeferredLoadTask.IMPACT_USE) {
      impactCacheDeleter.emptyCache();
    }
  }
}

/// Interface for resources only used during code generation.
abstract class CodegenInputs {
  CheckedModeHelpers get checkedModeHelpers;
  RuntimeTypesSubstitutions get rtiSubstitutions;
  RecipeEncoder get rtiRecipeEncoder;
  Tracer get tracer;
  FixedNames get fixedNames;
}

class CodegenInputsImpl implements CodegenInputs {
  @override
  final CheckedModeHelpers checkedModeHelpers = new CheckedModeHelpers();

  @override
  final RuntimeTypesSubstitutions rtiSubstitutions;

  @override
  final RecipeEncoder rtiRecipeEncoder;

  @override
  final Tracer tracer;

  @override
  final FixedNames fixedNames;

  CodegenInputsImpl(this.rtiSubstitutions, this.rtiRecipeEncoder, this.tracer,
      this.fixedNames);
}
