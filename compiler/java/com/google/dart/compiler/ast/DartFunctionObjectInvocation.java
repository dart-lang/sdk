// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Function-object invocation AST node.
 */
public class DartFunctionObjectInvocation extends DartInvocation {

  private DartExpression target;

  public DartFunctionObjectInvocation(DartExpression target, List<DartExpression> args) {
    super(args);
    this.target = becomeParentOf(target);
  }

  @Override
  public DartExpression getTarget() {
    return target;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(target, visitor);
    visitor.visit(getArguments());
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitFunctionObjectInvocation(this);
  }
}
