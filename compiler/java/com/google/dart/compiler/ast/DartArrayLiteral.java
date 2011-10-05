// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart array literal value.
 */
public class DartArrayLiteral extends DartTypedLiteral {

  private final List<DartExpression> expressions;

  public DartArrayLiteral(boolean isConst, List<DartTypeNode> typeArguments,
                          List<DartExpression> expressions) {
    super(isConst, typeArguments);
    this.expressions = becomeParentOf(expressions);
  }

  public List<DartExpression> getExpressions() {
    return expressions;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      super.traverse(v, ctx);
      v.acceptWithInsertRemove(this, expressions);
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    super.visitChildren(visitor);
    visitor.visit(expressions);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitArrayLiteral(this);
  }
}
