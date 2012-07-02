// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(typeNode, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitTypeExpression(this);
  }
}
