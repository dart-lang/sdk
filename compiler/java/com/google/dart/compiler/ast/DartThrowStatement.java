// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'throw' statement.
 */
public class DartThrowStatement extends DartStatement {

  private DartExpression exception;

  public DartThrowStatement(DartExpression exception) {
    this.exception = becomeParentOf(exception);
  }

  public DartExpression getException() {
    return exception;
  }

  @Override
  public boolean isAbruptCompletingStatement() {
    return true;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    if (exception != null) {
      exception.accept(visitor);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitThrowStatement(this);
  }
}
