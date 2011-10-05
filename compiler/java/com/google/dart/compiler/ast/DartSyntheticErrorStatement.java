// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.ast;

/**
 * A statement node representing an unparseable statement.
 */
public class DartSyntheticErrorStatement extends DartStatement {

  private final String tokenString;

  public DartSyntheticErrorStatement() {
    this(null);
  }

  public DartSyntheticErrorStatement(String tokenString) {
    this.tokenString = tokenString;
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitSyntheticErrorStatement(this);
  }

  public String getTokenString() {
    return tokenString;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    v.visit(this, ctx);
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
  }
}
