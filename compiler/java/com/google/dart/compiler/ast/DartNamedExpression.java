// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a labeled expression (used in named method arguments).
 */
public class DartNamedExpression extends DartExpression {

  private DartIdentifier name;
  private DartExpression expression;

  public DartNamedExpression(DartIdentifier ident, DartExpression expression) {
    this.name = ident;
    this.expression = becomeParentOf(expression);
  }

  public DartIdentifier getName() {
    return name;
  }

  public DartExpression getExpression() {
    return expression;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (name != null) {
        name = becomeParentOf(v.accept(name));
      }
      if (expression != null) {
        expression = becomeParentOf(v.accept(expression));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (name != null) {
      name.accept(visitor);
    }
    if (expression != null) {
      expression.accept(visitor);
    }
    expression.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitNamedExpression(this);
  }
}
