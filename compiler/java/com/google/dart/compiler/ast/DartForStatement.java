// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'for' statement.
 */
public class DartForStatement extends DartStatement {

  private DartStatement init;
  private DartExpression condition;
  private DartExpression increment;
  private final int closeParenOffset;
  private DartStatement body;

  public DartForStatement(DartStatement init, DartExpression condition, DartExpression increment,
      int closeParenOffset, DartStatement body) {
    this.init = becomeParentOf(init);
    this.condition = becomeParentOf(condition);
    this.increment = becomeParentOf(increment);
    this.closeParenOffset = closeParenOffset;
    this.body = becomeParentOf(body);
  }

  public int getCloseParenOffset() {
    return closeParenOffset;
  }

  public DartStatement getBody() {
    return body;
  }

  public DartExpression getCondition() {
    return condition;
  }

  public DartExpression getIncrement() {
    return increment;
  }

  public DartStatement getInit() {
    return init;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(init, visitor);
    safelyVisitChild(condition, visitor);
    safelyVisitChild(increment, visitor);
    safelyVisitChild(body, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitForStatement(this);
  }
}
