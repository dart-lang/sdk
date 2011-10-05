// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'switch' statement.
 */
public class DartSwitchStatement extends DartStatement {

  private DartExpression expression;
  private final List<DartSwitchMember> members;

  public DartSwitchStatement(DartExpression expression, List<DartSwitchMember> members) {
    this.expression = becomeParentOf(expression);
    this.members = becomeParentOf(members);
  }

  public DartExpression getExpression() {
    return expression;
  }

  public List<DartSwitchMember> getMembers() {
    return members;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      expression = becomeParentOf(v.accept(expression));
      v.acceptWithInsertRemove(this, members);
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    expression.accept(visitor);
    visitor.visit(members);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitSwitchStatement(this);
  }
}
