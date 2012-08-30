// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart field definition.
 */
public class DartFieldDefinition extends DartNodeWithMetadata {

  private DartTypeNode typeNode;
  private final NodeList<DartField> fields = NodeList.create(this);

  public DartFieldDefinition(DartTypeNode typeNode, List<DartField> fields) {
    this.setTypeNode(typeNode);
    this.fields.addAll(fields);
  }

  public DartTypeNode getTypeNode() {
    return typeNode;
  }

  public void setTypeNode(DartTypeNode typeNode) {
    this.typeNode = becomeParentOf(typeNode);
  }

  public List<DartField> getFields() {
    return fields;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(typeNode, visitor);
    fields.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitFieldDefinition(this);
  }
}
