// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'for (.. in ..)' statement.
 */
public class DartForInStatement extends DartStatement {

  private DartStatement setup;
  private DartExpression iterable;
  private final int closeParenOffset;
  private DartStatement body;

  public DartForInStatement(DartStatement setup,
                            DartExpression iterable,
                            int closeParenOffset,
                            DartStatement body) {
    this.setup = becomeParentOf(setup);
    this.iterable = becomeParentOf(iterable);
    this.closeParenOffset = closeParenOffset;
    this.body = becomeParentOf(body);
  }

  public int getCloseParenOffset() {
    return closeParenOffset;
  }
  
  public DartStatement getBody() {
    return body;
  }

  public DartExpression getIterable() {
    return iterable;
  }

  public boolean introducesVariable() {
    return setup instanceof DartVariableStatement;
  }

  public DartIdentifier getIdentifier() {
    assert !introducesVariable();
    return (DartIdentifier) ((DartExprStmt) setup).getExpression();
  }

  public DartVariableStatement getVariableStatement() {
    assert introducesVariable();
    return (DartVariableStatement) setup;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(setup, visitor);
    safelyVisitChild(iterable, visitor);
    safelyVisitChild(body, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitForInStatement(this);
  }
}
