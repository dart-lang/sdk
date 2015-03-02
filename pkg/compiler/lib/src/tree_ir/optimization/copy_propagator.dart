// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of tree_ir.optimization;

/// Eliminates moving assignments, such as w := v, by assigning directly to w
/// at the definition of v.
///
/// This compensates for suboptimal register allocation, and merges closure
/// variables with local temporaries that were left behind when translating
/// out of CPS (where closure variables live in a separate space).
class CopyPropagator extends RecursiveVisitor with PassMixin {

  /// After visitStatement returns, [move] maps a variable v to an
  /// assignment A of form w := v, under the following conditions:
  /// - there are no reads or writes of w before A
  /// - A is the only use of v
  Map<Variable, Assign> move = <Variable, Assign>{};

  /// Like [move], except w is the key instead of v.
  Map<Variable, Assign> inverseMove = <Variable, Assign>{};

  ExecutableElement currentElement;

  void rewriteExecutableDefinition(ExecutableDefinition root) {
    currentElement = root.element;
    root.body = visitStatement(root.body);
  }

  rewriteFunctionDefinition(FunctionDefinition node) {
    if (node.isAbstract) return;
    rewriteExecutableDefinition(node);

    // Try to propagate moving assignments into function parameters.
    // For example:
    // foo(x) {
    //   var v1 = x;
    //   BODY
    // }
    //   ==>
    // foo(v1) {
    //   BODY
    // }

    // Variables must not occur more than once in the parameter list, so
    // invalidate all moving assignments that would propagate a parameter
    // into another parameter. For example:
    // foo(x,y) {
    //   y = x;
    //   BODY
    // }
    // Cannot declare function as foo(x,x)!
    node.parameters.forEach(invalidateMovingAssignment);

    // Now do the propagation.
    for (int i = 0; i < node.parameters.length; i++) {
      Variable param = node.parameters[i];
      Variable replacement = copyPropagateVariable(param);
      replacement.element = param.element; // Preserve parameter name.
      node.parameters[i] = replacement;
    }
  }

  rewriteConstructorDefinition(ConstructorDefinition node) {
    if (node.isAbstract) return;
    node.initializers.forEach(visitExpression);
    rewriteExecutableDefinition(node);


    // Try to propagate moving assignments into function parameters.
    // For example:
    // foo(x) {
    //   var v1 = x;
    //   BODY
    // }
    //   ==>
    // foo(v1) {
    //   BODY
    // }

    // Variables must not occur more than once in the parameter list, so
    // invalidate all moving assignments that would propagate a parameter
    // into another parameter. For example:
    // foo(x,y) {
    //   y = x;
    //   BODY
    // }
    // Cannot declare function as foo(x,x)!
    node.parameters.forEach(invalidateMovingAssignment);

    // Now do the propagation.
    for (int i = 0; i < node.parameters.length; i++) {
      Variable param = node.parameters[i];
      Variable replacement = copyPropagateVariable(param);
      replacement.element = param.element; // Preserve parameter name.
      node.parameters[i] = replacement;
    }

  }


  Statement visitBasicBlock(Statement node) {
    node = visitStatement(node);
    move.clear();
    inverseMove.clear();
    return node;
  }

  /// Remove an assignment of form [w] := v from the move maps.
  void invalidateMovingAssignment(Variable w) {
    Assign movingAssignment = inverseMove.remove(w);
    if (movingAssignment != null) {
      VariableUse def = movingAssignment.definition;
      move.remove(def.variable);
    }
  }

  visitVariableUse(VariableUse node) {
    // We found a use of w; we can't propagate assignments across this use.
    invalidateMovingAssignment(node.variable);
  }

  /**
   * Called when a definition of [v] is encountered.
   * Attempts to propagate the assignment through a moving assignment.
   * Returns the variable to be assigned into, defaulting to [v] itself if
   * no optimization could be performed.
   */
  Variable copyPropagateVariable(Variable v) {
    Assign movingAssign = move[v];
    if (movingAssign != null) {
      // We found the pattern:
      //   v := EXPR
      //   BLOCK   (does not use w)
      //   w := v  (only use of v)
      //
      // Rewrite to:
      //   w := EXPR
      //   BLOCK
      //   w := w  (to be removed later)
      Variable w = movingAssign.variable;

      // Make w := w.
      // We can't remove the statement from here because we don't have
      // parent pointers. So just make it a no-op so it can be removed later.
      movingAssign.definition = new VariableUse(w);

      // The intermediate variable 'v' should now be orphaned, so don't bother
      // updating its read/write counters.

      // Make w := EXPR
      ++w.writeCount;
      return w;
    }
    return v;
  }

  Statement visitAssign(Assign node) {
    node.next = visitStatement(node.next);
    node.variable = copyPropagateVariable(node.variable);

    // If a moving assignment w := v exists later, and we assign to w here,
    // the moving assignment is no longer a candidate for copy propagation.
    invalidateMovingAssignment(node.variable);

    visitExpression(node.definition);

    // If this is a moving assignment w := v, with this being the only use of v,
    // try to propagate it backwards.  Do not propagate assignments where w
    // is from an outer function scope.
    if (node.definition is VariableUse) {
      VariableUse definition = node.definition;
      if (definition.variable.readCount == 1 &&
          node.variable.host == currentElement) {
        move[definition.variable] = node;
        inverseMove[node.variable] = node;
      }
    }

    return node;
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    node.next = visitBasicBlock(node.next);
    node.body = visitStatement(node.body);
    return node;
  }

  Statement visitReturn(Return node) {
    visitExpression(node.value);
    return node;
  }

  Statement visitBreak(Break node) {
    return node;
  }

  Statement visitContinue(Continue node) {
    return node;
  }

  Statement visitIf(If node) {
    visitExpression(node.condition);
    node.thenStatement = visitBasicBlock(node.thenStatement);
    node.elseStatement = visitBasicBlock(node.elseStatement);
    return node;
  }

  Statement visitWhileTrue(WhileTrue node) {
    node.body = visitBasicBlock(node.body);
    return node;
  }

  Statement visitWhileCondition(WhileCondition node) {
    throw "WhileCondition before LoopRewriter";
  }

  Statement visitTry(Try node) {
    node.tryBody = visitBasicBlock(node.tryBody);
    node.catchBody = visitBasicBlock(node.catchBody);
    return node;
  }

  Statement visitFunctionDeclaration(FunctionDeclaration node) {
    // Unlike var declarations, function declarations are not hoisted, so we
    // can't do copy propagation of the variable.
    new CopyPropagator().rewrite(node.definition);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    node.next = visitStatement(node.next);
    visitExpression(node.expression);
    return node;
  }

  Statement visitSetField(SetField node) {
    node.next = visitStatement(node.next);
    visitExpression(node.value);
    visitExpression(node.object);
    return node;
  }

  void visitFunctionExpression(FunctionExpression node) {
    new CopyPropagator().rewrite(node.definition);
  }

  void visitFieldInitializer(FieldInitializer node) {
    visitStatement(node.body);
  }

}
