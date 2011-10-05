// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'while' statement.
 */
public class DartWhileStatement extends DartStatement {

  private DartExpression condition;
  private DartStatement body;

  public DartWhileStatement(DartExpression condition, DartStatement body) {
    this.condition = becomeParentOf(condition);
    this.body = becomeParentOf(body);
  }

  public DartStatement getBody() {
    return body;
  }

  public DartExpression getCondition() {
    return condition;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      condition = becomeParentOf(v.accept(condition));
      body = becomeParentOf(v.accept(body));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitWhileStatement(this);
  }
}
