// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    if (expr != null) {
      expr.accept(visitor);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitExprStmt(this);
  }
}
