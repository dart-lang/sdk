// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'assert' statement.
 */
public class DartAssertStatement extends DartStatement {

  private final DartExpression condition;

  public DartAssertStatement(DartExpression condition) {
    this.condition = becomeParentOf(condition);
  }

  public DartExpression getCondition() {
    return condition;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(condition, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitAssertStatement(this);
  }
}
