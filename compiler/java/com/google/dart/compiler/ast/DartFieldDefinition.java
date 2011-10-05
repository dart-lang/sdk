// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart field definition.
 */
public class DartFieldDefinition extends DartNode {

  private DartTypeNode typeNode;
  private final List<DartField> fields;

  public DartFieldDefinition(DartTypeNode typeNode, List<DartField> fields) {
    this.setTypeNode(typeNode);
    this.fields = becomeParentOf(fields);
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
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (getTypeNode() != null) {
        setTypeNode(v.accept(getTypeNode()));
      }
      v.acceptWithInsertRemove(this, getFields());
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (getTypeNode() != null) {
      getTypeNode().accept(visitor);
    }
    visitor.visit(getFields());
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitFieldDefinition(this);
  }
}
