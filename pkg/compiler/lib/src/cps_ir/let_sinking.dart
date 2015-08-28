// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.let_sinking;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';
import 'loop_hierarchy.dart';

/// Sinks single-use primitives to the use when this is safe and profitable.
///
/// To avoid sinking non-constant primitives into loops, this pass performs a
/// control-flow analysis to determine the effective nesting of loops.
///
/// In the example below, the value 'p' can be sunk to its use site in the
/// 'else' branch because that branch is not effectively part of a loop,
/// despite being lexically nested in a recursive continuation.
///
///   let prim p = getInterceptor(<something>)
///   let rec kont x =
///     if (<loop condition>)
///       <loop body>
///       InvokeContinuation kont x'
///     else
///       <after loop>
///       return p.foo()
///
class LetSinker extends RecursiveVisitor implements Pass {
  String get passName => 'Let sinking';

  LoopHierarchy loopHierarchy;
  List<Continuation> stack = <Continuation>[];

  /// Maps a sinkable primitive to its loop header.
  Map<Primitive, Continuation> loopHeaderForPrimitive =
      <Primitive, Continuation>{};

  Continuation currentLoopHeader;

  void rewrite(FunctionDefinition node) {
    new ParentVisitor().visit(node);
    loopHierarchy = new LoopHierarchy(node);
    visit(node.body);
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    Primitive prim = node.primitive;
    if (prim.hasExactlyOneUse && prim.isSafeForReordering) {
      // This can potentially be sunk. Register the loop header, so when we
      // find the use site, we can check if they are in the same loop.
      loopHeaderForPrimitive[prim] = currentLoopHeader;
      pushAction(() {
        if (node.primitive != null) {
          // The primitive could not be sunk. Try to sink dependencies here.
          visit(node.primitive);
        } else {
          // The primitive was sunk. Destroy the old LetPrim.
          InteriorNode parent = node.parent;
          parent.body = node.body;
          node.body.parent = parent;
        }
      });
    } else {
      visit(node.primitive);
    }

    // Visit the body, wherein this primitive may be sunk to its use site.
    return node.body;
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    Continuation oldLoopHeader = currentLoopHeader;
    pushAction(() {
      currentLoopHeader = oldLoopHeader;
    });
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
    return cont.body;
  }

  void processReference(Reference ref) {
    Definition definition = ref.definition;
    if (definition is Primitive && 
        definition is! Parameter &&
        definition.hasExactlyOneUse &&
        definition.isSafeForReordering) {
      // Check if use is in the same loop.
      Continuation bindingLoop = loopHeaderForPrimitive.remove(definition);
      if (bindingLoop == currentLoopHeader || definition is Constant) {
        // Sink the definition.

        Expression use = getEnclosingExpression(ref.parent);
        LetPrim binding = definition.parent;
        binding.primitive = null;  // Mark old binding for deletion.
        LetPrim newBinding = new LetPrim(definition);
        definition.parent = newBinding;
        InteriorNode useParent = use.parent;
        useParent.body = newBinding;
        newBinding.body = use;
        use.parent = newBinding;
        newBinding.parent = useParent;

        // Now that the final binding location has been found, sink the
        // dependencies of the definition down here as well.
        visit(definition); 
      }
    }
  }

  Expression getEnclosingExpression(Node node) {
    while (node is! Expression) {
      node = node.parent;
    }
    return node;
  }
}

