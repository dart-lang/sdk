// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'if' statement.
 */
public class DartIfStatement extends DartStatement {

  private DartExpression condition;
  private DartStatement thenStmt;
  private DartStatement elseStmt;

  public DartIfStatement(DartExpression condition, DartStatement thenStmt, DartStatement elseStmt) {
    this.condition = becomeParentOf(condition);
    this.thenStmt = becomeParentOf(thenStmt);
    this.elseStmt = becomeParentOf(elseStmt);
  }

  public DartExpression getCondition() {
    return condition;
  }

  public DartStatement getElseStatement() {
    return elseStmt;
  }

  public DartStatement getThenStatement() {
    return thenStmt;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      condition = becomeParentOf(v.accept(condition));
      thenStmt = becomeParentOf(v.accept(thenStmt));
      if (elseStmt != null) {
        elseStmt = becomeParentOf(v.accept(elseStmt));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    condition.accept(visitor);
    thenStmt.accept(visitor);
    if (elseStmt != null) {
      elseStmt.accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitIfStatement(this);
  }
}
