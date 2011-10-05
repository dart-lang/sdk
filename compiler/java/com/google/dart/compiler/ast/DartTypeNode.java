// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.type.Type;

import java.util.ArrayList;
import java.util.List;

/**
 * Representation of a Dart type name.
 */
public class DartTypeNode extends DartNode {

  private DartNode identifier;
  private List<DartTypeNode> typeArguments = new ArrayList<DartTypeNode>();
  private Type type;

  public DartTypeNode(DartNode identifier) {
   this(identifier, new ArrayList<DartTypeNode>());
  }

  public DartTypeNode(DartNode identifier, List<DartTypeNode> typeArguments) {
    this.identifier = becomeParentOf(identifier);
    this.typeArguments = becomeParentOf(typeArguments);
  }

  public DartNode getIdentifier() {
    return identifier;
  }

  public List<DartTypeNode> getTypeArguments() {
    return typeArguments;
  }

  @Override
  public void setType(Type type) {
    this.type = type;
  }

  @Override
  public Type getType() {
    return type;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      identifier = becomeParentOf(v.accept(identifier));
      v.acceptWithInsertRemove(this, typeArguments);
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    identifier.accept(visitor);
    visitor.visit(typeArguments);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitTypeNode(this);
  }
}
