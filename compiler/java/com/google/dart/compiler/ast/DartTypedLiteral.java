// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.type.InterfaceType;

import java.util.List;

public abstract class DartTypedLiteral extends DartExpression {
  private final boolean isConst;
  private final NodeList<DartTypeNode> typeArguments = NodeList.create(this);

  DartTypedLiteral(boolean isConst, List<DartTypeNode> typeArguments) {
    this.isConst = isConst;
    this.typeArguments.addAll(typeArguments);
  }

  public boolean isConst() {
    return isConst;
  }

  public List<DartTypeNode> getTypeArguments() {
    return typeArguments;
  }

  @Override
  public InterfaceType getType() {
    return (InterfaceType) super.getType();
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    typeArguments.accept(visitor);
  }
}
