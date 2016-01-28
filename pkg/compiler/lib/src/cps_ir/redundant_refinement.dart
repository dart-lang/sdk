// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.redundant_refinement;

import 'cps_ir_nodes.dart';
import 'optimizers.dart' show Pass;
import 'type_mask_system.dart';

/// Removes [Refinement] nodes where the input value is already known to
/// satisfy the refinement type.
///
/// Note: This pass improves loop-invariant code motion in the GVN pass because
/// GVN will currently not hoist a primitive across a refinement guard.
/// But some opportunities for hoisting are still missed.  A field access can
/// safely be hoisted across a non-redundant refinement as long as the less
/// refined value is still known to have the field.  For example:
///
///     class A { var field; }
///     class B extends A {}
///
///     var x = getA();       // Return type is subclass of A.
///     while (x is B) {      // Refinement to B is not redundant.
///         x.field.baz++;    // x.field is safe for hoisting,
///     }                     // but blocked by the refinement node.
///
/// Ideally, this pass should go away and GVN should handle refinements
/// directly.
class RedundantRefinementEliminator extends TrampolineRecursiveVisitor
                                    implements Pass {
  String get passName => 'Redundant refinement elimination';

  TypeMaskSystem typeSystem;

  RedundantRefinementEliminator(this.typeSystem);

  void rewrite(FunctionDefinition node) {
    visit(node);
  }

  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    if (node.primitive is Refinement) {
      Refinement refinement = node.primitive;
      Primitive value = refinement.value.definition;
      if (typeSystem.isMorePreciseOrEqual(value.type, refinement.refineType)) {
        refinement..replaceUsesWith(value)..destroy();
        node.remove();
        return next;
      }
    }
    return next;
  }
}
