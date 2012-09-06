// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'while' statement.
 */
public class DartWhileStatement extends DartStatement {

  private DartExpression condition;
  private final int closeParenOffset;
  private DartStatement body;

  public DartWhileStatement(DartExpression condition, int closeParenOffset, DartStatement body) {
    this.condition = becomeParentOf(condition);
    this.closeParenOffset = closeParenOffset;
    this.body = becomeParentOf(body);
  }

  public DartStatement getBody() {
    return body;
  }

  public DartExpression getCondition() {
    return condition;
  }
  
  public int getCloseParenOffset() {
    return closeParenOffset;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(condition, visitor);
    safelyVisitChild(body, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitWhileStatement(this);
  }
}
