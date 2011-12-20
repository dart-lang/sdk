// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.type.Type;

import java.util.Collections;
import java.util.List;

public class DartParameterizedTypeNode extends DartExpression {
  private DartExpression expression;
  private List<DartTypeParameter> typeParameters;
  private Type type;

  public DartParameterizedTypeNode(DartExpression expression, List<DartTypeParameter> typeParameters) {
    setExpression(expression);
    setTypeParameters(typeParameters);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitParameterizedTypeNode(this);
  }

  public DartExpression getExpression() {
    return expression;
  }

  @Override
  public Type getType() {
    return type;
  }

  public List<DartTypeParameter> getTypeParameters() {
    return typeParameters;
  }

  public void setExpression(DartExpression expression) {
    this.expression = becomeParentOf(expression);
  }

  @Override
  public void setType(Type type) {
    this.type = type;
  }

  public void setTypeParameters(List<DartTypeParameter> typeParameters) {
    if (typeParameters == null) {
      typeParameters = Collections.emptyList();
    }
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
}
