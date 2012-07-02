// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(expression, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitParenthesizedExpression(this);
  }
}
