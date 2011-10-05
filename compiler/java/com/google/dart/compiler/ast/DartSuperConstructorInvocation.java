// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.ConstructorElement;

import java.util.List;

/**
 * Super constructor invocation AST node.
 */
public class DartSuperConstructorInvocation extends DartInvocation implements HasSymbol {

  private DartIdentifier name;
  private ConstructorElement symbol;

  public DartSuperConstructorInvocation(DartIdentifier name, List<DartExpression> args) {
    super(args);
    this.name = becomeParentOf(name);
  }

  public String getConstructorName() {
    if (name == null) {
      return null;
    }
    return name.getTargetName();
  }

  public DartIdentifier getName() {
    return name;
  }

  public void setName(DartIdentifier newName) {
    name = becomeParentOf(newName);
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.symbol = (ConstructorElement) symbol;
  }

  @Override
  public ConstructorElement getSymbol() {
    return symbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (name != null) {
        name = becomeParentOf(v.accept(name));
      }
      v.acceptWithInsertRemove(this, getArgs());
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (name != null) {
      name.accept(visitor);
    }
    visitor.visit(getArgs());
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitSuperConstructorInvocation(this);
  }
}
