// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart conditional expression.
 */
public class DartConditional extends DartExpression {

  private DartExpression condition;
  private DartExpression elseExpr;
  private DartExpression thenExpr;

  public DartConditional(DartExpression condition, DartExpression thenExpr,
      DartExpression elseExpr) {
    this.condition = becomeParentOf(condition);
    this.thenExpr = becomeParentOf(thenExpr);
    this.elseExpr = becomeParentOf(elseExpr);
  }

  public DartExpression getCondition() {
    return condition;
  }

  public DartExpression getElseExpression() {
    return elseExpr;
  }

  public DartExpression getThenExpression() {
    return thenExpr;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(condition, visitor);
    safelyVisitChild(thenExpr, visitor);
    safelyVisitChild(elseExpr, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitConditional(this);
  }
}
