// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart array literal value.
 */
public class DartArrayLiteral extends DartTypedLiteral {

  private final NodeList<DartExpression> expressions = NodeList.create(this);

  public DartArrayLiteral(boolean isConst, List<DartTypeNode> typeArguments,
                          List<DartExpression> expressions) {
    super(isConst, typeArguments);
    this.expressions.addAll(expressions);
  }

  public List<DartExpression> getExpressions() {
    return expressions;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    expressions.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitArrayLiteral(this);
  }
}
