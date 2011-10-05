// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the "assert" statement.
 */
public class DartAssertion extends DartStatement {
  private DartExpression expression;
  private DartExpression message;

  public DartAssertion(DartExpression expression, DartExpression message) {
    this.expression = becomeParentOf(expression);
    this.message = becomeParentOf(message);
  }

  public void setExpression(DartExpression expression) {
    this.expression = expression;
  }

  public DartExpression getExpression() {
    return expression;
  }

  public void setMessage(DartExpression message) {
    this.message = message;
  }

  public DartExpression getMessage() {
    return message;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      expression = becomeParentOf(v.accept(expression));
      if (message != null) {
        message = becomeParentOf(v.accept(message));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    expression.accept(visitor);
    if (message != null) {
      message.accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitAssertion(this);
  }
}
