// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the "assert" statement.
 */
public class DartAssertion extends DartStatement {
  private DartExpression expression;

  public DartAssertion(DartExpression expression) {
    this.expression = becomeParentOf(expression);
  }

  public void setExpression(DartExpression expression) {
    this.expression = expression;
  }

  public DartExpression getExpression() {
    return expression;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    expression.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitAssertion(this);
  }
}
