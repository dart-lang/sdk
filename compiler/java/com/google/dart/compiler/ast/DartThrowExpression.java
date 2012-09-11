// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'throw' expression.
 */
public class DartThrowExpression extends DartExpression {

  private DartExpression exception;

  public DartThrowExpression(DartExpression exception) {
    this.exception = becomeParentOf(exception);
  }

  public DartExpression getException() {
    return exception;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(exception, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitThrowExpression(this);
  }
}
