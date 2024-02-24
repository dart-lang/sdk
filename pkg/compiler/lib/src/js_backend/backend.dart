// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import '../common.dart';
import '../common/codegen.dart';
import '../common/tasks.dart';
import '../elements/entities.dart';
import '../inferrer/types.dart';
import '../js_model/elements.dart';
import 'annotations.dart';
import 'codegen_inputs.dart';

abstract class FunctionCompiler {
  void initialize(
      GlobalTypeInferenceResults globalInferenceResults, CodegenInputs codegen);

  /// Generates JavaScript code for [member].
  CodegenResult compile(MemberEntity member);

  List<CompilerTask> get tasks;
}

enum _Decision {
  unknown,
  mustNotInline,
  mayInlineInLoopMustNotOutside,
  canInlineInLoopMustNotOutside,
  canInlineInLoopMayInlineOutside,
  canInline,
}

/*
 * Invariants:
 *   canInline(function) implies canInline(function, insideLoop:true)
 *   !canInline(function, insideLoop: true) implies !canInline(function)
 */
class FunctionInlineCache {
  final AnnotationsData _annotationsData;

  final Map<FunctionEntity, _Decision> _cachedDecisions = {};

  FunctionInlineCache(this._annotationsData) {}

  /// Checks that [method] is the canonical representative for this method.
  ///
  /// For a [MethodElement] this means it must be the declaration element.
  bool checkFunction(FunctionEntity method) {
    return '$method'.startsWith(jsElementPrefix);
  }

  // Returns `true`/`false` if we have a cached decision.
  // Returns `null` otherwise.
  bool? canInline(FunctionEntity element, {required bool insideLoop}) {
    assert(checkFunction(element), failedAt(element));

    // TODO(sra): Have annotations for mustInline / noInline for constructor
    // bodies. (There used to be some logic here to have constructor bodies,
    // inherit the settings from annotations on the generative
    // constructor. This was conflated with the heuristic decisions, leading
    // to lack of inlining where it was beneficial.)

    final decision = _cachedDecisions[element] ?? _Decision.unknown;

    if (insideLoop) {
      switch (decision) {
        case _Decision.mustNotInline:
          return false;

        case _Decision.unknown:
        case _Decision.mayInlineInLoopMustNotOutside:
          // We know we can't inline outside a loop, but don't know for the
          // loop case. Return `null` to indicate that we don't know yet.
          return null;

        case _Decision.canInlineInLoopMustNotOutside:
        case _Decision.canInlineInLoopMayInlineOutside:
        case _Decision.canInline:
          return true;
      }
    } else {
      switch (decision) {
        case _Decision.mustNotInline:
        case _Decision.mayInlineInLoopMustNotOutside:
        case _Decision.canInlineInLoopMustNotOutside:
          return false;

        case _Decision.unknown:
        case _Decision.canInlineInLoopMayInlineOutside:
          // We know we can inline inside a loop, but don't know for the
          // non-loop case. Return `null` to indicate that we don't know yet.
          return null;

        case _Decision.canInline:
          return true;
      }
    }
  }

  void markAsInlinable(FunctionEntity element, {required bool insideLoop}) {
    assert(checkFunction(element), failedAt(element));
    final oldDecision = _cachedDecisions[element] ?? _Decision.unknown;

    if (insideLoop) {
      switch (oldDecision) {
        case _Decision.mustNotInline:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _Decision.unknown:
          // We know that it can be inlined in a loop, but don't know about the
          // non-loop case yet.
          _cachedDecisions[element] = _Decision.canInlineInLoopMayInlineOutside;
          break;

        case _Decision.mayInlineInLoopMustNotOutside:
          _cachedDecisions[element] = _Decision.canInlineInLoopMustNotOutside;
          break;

        case _Decision.canInlineInLoopMustNotOutside:
        case _Decision.canInlineInLoopMayInlineOutside:
        case _Decision.canInline:
          // Do nothing.
          break;
      }
    } else {
      switch (oldDecision) {
        case _Decision.mustNotInline:
        case _Decision.mayInlineInLoopMustNotOutside:
        case _Decision.canInlineInLoopMustNotOutside:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _Decision.unknown:
        case _Decision.canInlineInLoopMayInlineOutside:
          _cachedDecisions[element] = _Decision.canInline;
          break;

        case _Decision.canInline:
          // Do nothing.
          break;
      }
    }
  }

  void markAsNonInlinable(FunctionEntity element, {bool insideLoop = true}) {
    assert(checkFunction(element), failedAt(element));
    final oldDecision = _cachedDecisions[element] ?? _Decision.unknown;

    if (insideLoop) {
      switch (oldDecision) {
        case _Decision.canInlineInLoopMustNotOutside:
        case _Decision.canInlineInLoopMayInlineOutside:
        case _Decision.canInline:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _Decision.mayInlineInLoopMustNotOutside:
        case _Decision.unknown:
          _cachedDecisions[element] = _Decision.mustNotInline;
          break;

        case _Decision.mustNotInline:
          // Do nothing.
          break;
      }
    } else {
      switch (oldDecision) {
        case _Decision.canInline:
          throw failedAt(
              element,
              "Can't mark $element as non-inlinable and inlinable at the "
              "same time.");

        case _Decision.unknown:
          // We can't inline outside a loop, but we might still be allowed to do
          // so outside.
          _cachedDecisions[element] = _Decision.mayInlineInLoopMustNotOutside;
          break;

        case _Decision.canInlineInLoopMayInlineOutside:
          // We already knew that the function could be inlined inside a loop,
          // but didn't have information about the non-loop case. Now we know
          // that it can't be inlined outside a loop.
          _cachedDecisions[element] = _Decision.canInlineInLoopMustNotOutside;
          break;

        case _Decision.mayInlineInLoopMustNotOutside:
        case _Decision.canInlineInLoopMustNotOutside:
        case _Decision.mustNotInline:
          // Do nothing.
          break;
      }
    }
  }

  bool markedAsNoInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    return _annotationsData.hasNoInline(element);
  }

  bool markedAsTryInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    return _annotationsData.hasTryInline(element);
  }
}
