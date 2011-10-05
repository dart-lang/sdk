// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      condition = becomeParentOf(v.accept(condition));
      thenExpr = becomeParentOf(v.accept(thenExpr));
      elseExpr = becomeParentOf(v.accept(elseExpr));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    condition.accept(visitor);
    thenExpr.accept(visitor);
    elseExpr.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitConditional(this);
  }
}
