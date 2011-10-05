// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.collect.Lists;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;

import java.util.List;

public abstract class DartTypedLiteral extends DartExpression {
  private List<DartTypeNode> typeArguments;
  private final boolean isConst;
  private InterfaceType type;

  DartTypedLiteral(boolean isConst, List<DartTypeNode> typeArguments) {
    this.isConst = isConst;
    setTypeArguments(typeArguments);
  }

  public boolean isConst() {
    return isConst;
  }

  public void setTypeArguments(List<DartTypeNode> typeArguments) {
    if (typeArguments == null) {
      typeArguments = Lists.newArrayList();
    }
    this.typeArguments = becomeParentOf(typeArguments);
  }

  /**
   * @return a non-null list
   */
  public List<DartTypeNode> getTypeArguments() {
    return typeArguments;
  }

  @Override
  public void setType(Type type) {
    this.type = (InterfaceType) type;
  }

  @Override
  public InterfaceType getType() {
    return type;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (typeArguments.size() > 0) {
      v.acceptWithInsertRemove(this, typeArguments);
    }
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (typeArguments.size() > 0) {
      visitor.visit(getTypeArguments());
    }
  }
}
