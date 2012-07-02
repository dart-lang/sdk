// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'var' statement.
 */
public class DartVariableStatement extends DartStatement {

  private final NodeList<DartVariable> vars = NodeList.create(this);
  private DartTypeNode typeNode;
  private final Modifiers modifiers;

  public DartVariableStatement(List<DartVariable> vars, DartTypeNode type) {
    this(vars, type, Modifiers.NONE);
  }

  public DartVariableStatement(List<DartVariable> vars, DartTypeNode type, Modifiers modifiers) {
    this.vars.addAll(vars);
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
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(typeNode, visitor);
    vars.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitVariableStatement(this);
  }
}
