// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cps_ir.optimization.remove_refinements;

import 'optimizers.dart' show Pass;
import 'cps_ir_nodes.dart';

/// Removes all [Refinement] nodes from the IR.
///
/// This simplifies subsequent passes that don't rely on path-sensitive
/// type information but depend on equality between primitives.
class RemoveRefinements extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Remove refinement nodes';

  void rewrite(FunctionDefinition node) {
    visit(node);
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    if (node.primitive is Refinement) {
      Refinement refinement = node.primitive;
      refinement.value.definition.substituteFor(refinement);
      refinement.destroy();
      node.remove();
    }
    return next;
  }
}
