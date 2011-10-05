// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart parenthesized expression.
 */
public class DartParenthesizedExpression extends DartExpression {

  private DartExpression expression;

  public DartParenthesizedExpression(DartExpression expression) {
    this.expression = becomeParentOf(expression);
  }

  public DartExpression getExpression() {
    return expression;
  }

  public void setExpression(DartExpression newExpression) {
    expression = newExpression;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      expression = becomeParentOf(v.accept(expression));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    expression.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitParenthesizedExpression(this);
  }
}
