// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
  private final int closeParenOffset;
  private final int elseTokenOffset;

  public DartIfStatement(DartExpression condition, int closeParenOffset, DartStatement thenStmt,
      int elseTokenOffset, DartStatement elseStmt) {
    this.condition = becomeParentOf(condition);
    this.closeParenOffset = closeParenOffset;
    this.thenStmt = becomeParentOf(thenStmt);
    this.elseTokenOffset = elseTokenOffset;
    this.elseStmt = becomeParentOf(elseStmt);
  }

  public DartExpression getCondition() {
    return condition;
  }

  public int getCloseParenOffset() {
    return closeParenOffset;
  }

  public DartStatement getThenStatement() {
    return thenStmt;
  }

  public int getElseTokenOffset() {
    return elseTokenOffset;
  }

  public DartStatement getElseStatement() {
    return elseStmt;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(condition, visitor);
    safelyVisitChild(thenStmt, visitor);
    safelyVisitChild(elseStmt, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitIfStatement(this);
  }
}
