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
  private boolean isCascade;

  public DartFunctionObjectInvocation(DartExpression target, List<DartExpression> args) {
    this(target, false, args);
  }

  public DartFunctionObjectInvocation(DartExpression target, boolean isCascade,
                                      List<DartExpression> args) {
    super(args);
    this.target = becomeParentOf(target);
    this.isCascade = isCascade;
  }

  @Override
  public DartExpression getTarget() {
    return target;
  }

  public DartExpression getRealTarget() {
    if (isCascade) {
      DartNode ancestor = getParent();
      while (!(ancestor instanceof DartCascadeExpression)) {
        if (ancestor == null) {
          return target;
        }
        ancestor = ancestor.getParent();
      }
      return ((DartCascadeExpression) ancestor).getTarget();
    }
    return target;
  }

  public boolean isCascade() {
    return isCascade;
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
