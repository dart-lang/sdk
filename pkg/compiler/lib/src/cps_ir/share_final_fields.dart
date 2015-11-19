// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.share_final_fields;

import 'optimizers.dart';
import 'cps_ir_nodes.dart';
import 'loop_hierarchy.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../types/types.dart' show TypeMask;

/// Removes redundant GetField operations.
///
/// The pass performs these optimizations for field loads:
/// - share GetFields of final fields when one is in scope of the other.
/// - pull GetField operations of final fields out of loops when safe (object is
///   not null).
///
/// This pass only optimizes final fields and should be replaced with a full
/// load elimination pass.
class ShareFinalFields extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Share final fields';

  /// The innermost loop containing a given primitive.
  final Map<Primitive, Continuation> loopHeaderFor =
      <Primitive, Continuation>{};

  // field -> receiver -> GetField
  Map<FieldElement, Map<Primitive, Primitive>> fieldValues =
      <FieldElement, Map<Primitive, Primitive>>{};

  /// Interceptors that have been hoisted out of a given loop.
  final Map<Continuation, List<GetField>> loopHoistedGetters =
      <Continuation, List<GetField>>{};

  JavaScriptBackend backend;
  LoopHierarchy loopHierarchy;
  Continuation currentLoopHeader;

  ShareFinalFields(this.backend);

  void rewrite(FunctionDefinition node) {
    loopHierarchy = new LoopHierarchy(node);
    visit(node.body);
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    Continuation oldLoopHeader = currentLoopHeader;
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
    for (Parameter parameter in cont.parameters) {
      loopHeaderFor[parameter] = currentLoopHeader;
    }
    if (cont.isRecursive) {
      pushAction(() {
        // After the loop body has been processed, all values hoisted to this
        // loop fall out of scope and should be removed from the environment.
        List<GetField> hoisted = loopHoistedGetters[cont];
        if (hoisted != null) {
          for (GetField primitive in hoisted) {
            Primitive refinedReceiver = primitive.object.definition;
            Primitive receiver = refinedReceiver.effectiveDefinition;
            var map = fieldValues[primitive.field];
            assert(map[receiver] == primitive);
            map.remove(receiver);
          }
        }
      });
    }
    pushAction(() {
      currentLoopHeader = oldLoopHeader;
    });
    return cont.body;
  }

  Continuation getCurrentOuterLoop({Continuation scope}) {
    Continuation inner = null, outer = currentLoopHeader;
    while (outer != scope) {
      inner = outer;
      outer = loopHierarchy.getEnclosingLoop(outer);
    }
    return inner;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    loopHeaderFor[node.primitive] = currentLoopHeader;
    Expression next = node.body;
    if (node.primitive is! GetField) {
      return next;
    }
    GetField primitive = node.primitive;
    FieldElement field = primitive.field;

    if (!shouldShareField(field)) {
      return next;
    }

    Primitive refinedReceiver = primitive.object.definition;
    Primitive receiver = refinedReceiver.effectiveDefinition;

    // Try to reuse an existing load for the same input.
    var map = fieldValues.putIfAbsent(field, () => <Primitive,Primitive>{});
    Primitive existing = map[receiver];
    if (existing != null) {
      existing.substituteFor(primitive);
      primitive.destroy();
      node.remove();
      return next;
    }

    map[receiver] = primitive;

    if (primitive.objectIsNotNull) {
      // Determine how far the GetField can be lifted. The outermost loop that
      // contains the input binding should also contain the load.
      // Don't move above a refinement guard since that might be unsafe.

      // TODO(sra): We can move above a refinement guard provided the input is
      // still in scope and safe (non-null). We will have to replace
      // primitive.object with the most constrained refinement still in scope.
      Continuation referencedLoop =
          lowestCommonAncestor(loopHeaderFor[refinedReceiver],
                               currentLoopHeader);
      if (referencedLoop != currentLoopHeader) {
        Continuation hoistTarget = getCurrentOuterLoop(scope: referencedLoop);
        LetCont loopBinding = hoistTarget.parent;
        node.remove();
        node.insertAbove(loopBinding);
        // Remove the hoisted operations from the environment after processing
        // the loop.
        loopHoistedGetters
            .putIfAbsent(hoistTarget, () => <GetField>[])
            .add(primitive);
        return next;
      }
    }

    pushAction(() {
        var map = fieldValues[field];
        assert(map[receiver] == primitive);
        map.remove(receiver);
      });
    return next;
  }

  bool shouldShareField(FieldElement field) {
    // TODO(24781): This query is incorrect for fields assigned only via
    //
    //     super.field = ...
    //
    // return backend.compiler.world.fieldNeverChanges(field);

    // Native fields are getters with side effects (e.g. layout).
    if (backend.isNative(field)) return false;
    return field.isFinal || field.isConst;
  }

  /// Returns the the innermost loop that effectively encloses both
  /// c1 and c2 (or `null` if there is no such loop).
  Continuation lowestCommonAncestor(Continuation c1, Continuation c2) {
    int d1 = getDepth(c1), d2 = getDepth(c2);
    while (c1 != c2) {
      if (d1 <= d2) {
        c2 = loopHierarchy.getEnclosingLoop(c2);
        d2 = getDepth(c2);
      } else {
        c1 = loopHierarchy.getEnclosingLoop(c1);
        d1 = getDepth(c1);
      }
    }
    return c1;
  }

  int getDepth(Continuation loop) {
    if (loop == null) return -1;
    return loopHierarchy.loopDepth[loop];
  }
}
