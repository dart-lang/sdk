// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'case' switch member.
 */
public class DartCase extends DartSwitchMember {

  private DartExpression expr;
  private DartCase normalizedNode = this;

  public DartCase(DartExpression expr, DartLabel label, List<DartStatement> statements) {
    super(label, statements);
    this.expr = becomeParentOf(expr);
  }

  public DartExpression getExpr() {
    return expr;
  }

  public void setNormalizedNode(DartCase normalizedNode) {
    normalizedNode.setSourceInfo(this);
    this.normalizedNode = normalizedNode;
  }

  @Override
  public DartCase getNormalizedNode() {
    return normalizedNode;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      expr = becomeParentOf(v.accept(expr));
      v.acceptWithInsertRemove(this, getStatements());
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    expr.accept(visitor);
    super.visitChildren(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitCase(this);
  }
}
