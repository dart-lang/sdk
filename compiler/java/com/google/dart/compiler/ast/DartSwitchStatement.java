// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'switch' statement.
 */
public class DartSwitchStatement extends DartStatement {

  private DartExpression expression;
  private final NodeList<DartSwitchMember> members = NodeList.create(this);

  public DartSwitchStatement(DartExpression expression, List<DartSwitchMember> members) {
    this.expression = becomeParentOf(expression);
    this.members.addAll(members);
  }

  public DartExpression getExpression() {
    return expression;
  }

  public List<DartSwitchMember> getMembers() {
    return members;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(expression, visitor);
    members.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitSwitchStatement(this);
  }
}
