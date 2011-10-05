// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart expression-as-statement.
 */
public class DartExprStmt extends DartStatement {

  private DartExpression expr;

  public DartExprStmt(DartExpression expr) {
    this.expr = becomeParentOf(expr);
  }

  public DartExpression getExpression() {
    return expr;
  }

  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      expr =  becomeParentOf(v.accept(expr));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    expr.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitExprStmt(this);
  }
}
