// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'return' statement.
 */
public class DartReturnStatement extends DartStatement {

  private DartExpression value;

  public DartReturnStatement(DartExpression value) {
    this.value = becomeParentOf(value);
  }

  public DartExpression getValue() {
    return value;
  }

  @Override
  public boolean isAbruptCompletingStatement() {
    return true;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(value, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitReturnStatement(this);
  }
}
