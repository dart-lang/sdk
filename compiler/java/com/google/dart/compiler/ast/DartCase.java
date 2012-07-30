// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'case' switch member.
 */
public class DartCase extends DartSwitchMember {

  private DartExpression expr;

  public DartCase(DartExpression expr, List<DartLabel> labels, List<DartStatement> statements) {
    super(labels, statements); 
    this.expr = becomeParentOf(expr);
  }

  public DartExpression getExpr() {
    return expr;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(expr, visitor);
    super.visitChildren(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitCase(this);
  }
}
