// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
    this.name = becomeParentOf(ident);
    this.expression = becomeParentOf(expression);
  }

  public DartIdentifier getName() {
    return name;
  }

  public DartExpression getExpression() {
    return expression;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(name, visitor);
    safelyVisitChild(expression, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitNamedExpression(this);
  }
}
