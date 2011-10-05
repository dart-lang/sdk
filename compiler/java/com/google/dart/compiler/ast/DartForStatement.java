// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  private DartStatement body;

  public DartForStatement(DartStatement init, DartExpression condition, DartExpression increment,
      DartStatement body) {
    this.init = becomeParentOf(init);
    this.condition = becomeParentOf(condition);
    this.increment = becomeParentOf(increment);
    this.body = becomeParentOf(body);
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
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (init != null) {
        init = becomeParentOf(v.accept(init));
      }
      if (condition != null) {
        condition = becomeParentOf(v.accept(condition));
      }
      if (increment != null) {
        increment = becomeParentOf(v.accept(increment));
      }
      body = becomeParentOf(v.accept(body));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (init != null) {
      init.accept(visitor);
    }
    if (condition != null) {
      condition.accept(visitor);
    }
    if (increment != null) {
      increment.accept(visitor);
    }
    body.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitForStatement(this);
  }
}
