// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Representation of a Dart type name.
 */
public class DartTypeNode extends DartNode {

  private DartNode identifier;
  private NodeList<DartTypeNode> typeArguments = NodeList.create(this);

  public DartTypeNode(DartNode identifier) {
    this(identifier, null);
  }

  public DartTypeNode(DartNode identifier, List<DartTypeNode> typeArguments) {
    this.identifier = becomeParentOf(identifier);
    this.typeArguments.addAll(typeArguments);
  }

  public DartNode getIdentifier() {
    return identifier;
  }

  public List<DartTypeNode> getTypeArguments() {
    return typeArguments;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    identifier.accept(visitor);
    typeArguments.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitTypeNode(this);
  }
}
