// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.type.Type;

import java.util.List;

public class DartParameterizedTypeNode extends DartExpression {
  private DartExpression expression;
  private final NodeList<DartTypeParameter> typeParameters = NodeList.create(this);
  private Type type;

  public DartParameterizedTypeNode(DartExpression expression, List<DartTypeParameter> typeParameters) {
    setExpression(expression);
    this.typeParameters.addAll(typeParameters);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
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
    this.expression = expression;
  }

  @Override
  public void setType(Type type) {
    this.type = type;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    getExpression().accept(visitor);
    typeParameters.accept(visitor);
  }
}
