// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a type expression at the right hand side of an 'is'.
 */
public class DartTypeExpression extends DartExpression {

  private DartTypeNode typeNode;

  public DartTypeExpression(DartTypeNode type) {
    this.typeNode = becomeParentOf(type);
  }

  public DartTypeNode getTypeNode() {
    return typeNode;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      typeNode = becomeParentOf(v.accept(typeNode));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    typeNode.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitTypeExpression(this);
  }
}
