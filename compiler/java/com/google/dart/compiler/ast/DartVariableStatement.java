// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'var' statement.
 */
public class DartVariableStatement extends DartStatement {

  private final List<DartVariable> vars;
  private DartTypeNode typeNode;
  private final Modifiers modifiers;

  public DartVariableStatement(List<DartVariable> vars, DartTypeNode type) {
    this(vars, type, Modifiers.NONE);
  }

  public DartVariableStatement(List<DartVariable> vars, DartTypeNode type, Modifiers modifiers) {
    this.vars = becomeParentOf(vars);
    this.typeNode = becomeParentOf(type);
    this.modifiers = modifiers;
  }

  public List<DartVariable> getVariables() {
    return vars;
  }

  public DartTypeNode getTypeNode() {
    return typeNode;
  }

  public Modifiers getModifiers() {
    return modifiers;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (typeNode != null) {
        typeNode = becomeParentOf(v.accept(typeNode));
      }
      v.acceptWithInsertRemove(this, getVariables());
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (typeNode != null) {
      typeNode.accept(visitor);
    }
    visitor.visit(vars);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitVariableStatement(this);
  }
}
