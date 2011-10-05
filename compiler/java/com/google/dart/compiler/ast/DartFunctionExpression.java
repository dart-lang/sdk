// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.MethodElement;

/**
 * Represents a Dart 'function' expression.
 */
public class DartFunctionExpression extends DartExpression implements HasSymbol {

  // Not visited. Similar to DartDeclaration, but DartDeclaration shouldn't be
  // a statement or an expression.
  private DartIdentifier name;

  private final boolean isStmt;
  private MethodElement symbol;
  private DartFunction function;

  public DartFunctionExpression(DartIdentifier name, DartFunction function, boolean isStmt) {
    this.name = becomeParentOf(name);
    this.function = becomeParentOf(function);
    this.isStmt = isStmt;
  }

  public DartFunction getFunction() {
    return function;
  }

  public String getFunctionName() {
    if (name == null) {
      return null;
    }
    return name.getTargetName();
  }

  public DartIdentifier getName() {
    return name;
  }

  @Override
  public MethodElement getSymbol() {
    return symbol;
  }

  public boolean isStatement() {
    return isStmt;
  }

  public void setName(DartIdentifier newName) {
    name = becomeParentOf(newName);
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.symbol = (MethodElement) symbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      function = becomeParentOf(v.accept(function));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    function.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitFunctionExpression(this);
  }
}
