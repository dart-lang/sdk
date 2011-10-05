// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

public class DartParameterizedNode extends DartExpression {
  private DartExpression expression;
  private List<DartTypeParameter> typeParameters;

  public DartParameterizedNode(DartExpression expression, List<DartTypeParameter> typeParameters) {
    this.setExpression(becomeParentOf(expression));
    this.setTypeParameters(becomeParentOf(typeParameters));
  }

  public DartExpression getExpression() {
    return expression;
  }

  public void setExpression(DartExpression expression) {
    this.expression = becomeParentOf(expression);
  }

  public List<DartTypeParameter> getTypeParameters() {
    return typeParameters;
  }

  public void setTypeParameters(List<DartTypeParameter> typeParameters) {
    this.typeParameters = becomeParentOf(typeParameters);
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      setExpression(v.accept(getExpression()));
      setTypeParameters(v.acceptWithInsertRemove(this, getTypeParameters()));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    getExpression().accept(visitor);
    visitor.visit(getTypeParameters());
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitParameterizedNode(this);
  }
}
