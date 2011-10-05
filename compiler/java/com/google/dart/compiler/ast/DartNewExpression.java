// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.ConstructorElement;

import java.util.List;

/**
 * Represents a Dart 'new' expression.
 */
public class DartNewExpression extends DartInvocation implements HasSymbol {

  private DartNode constructor;
  private ConstructorElement typeSymbol;
  private final boolean isConst;

  public DartNewExpression(DartNode constructor, List<DartExpression> args, boolean isConst) {
    super(args);
    this.constructor = becomeParentOf(constructor);
    this.isConst = isConst;
  }

  public DartNode getConstructor() {
    return constructor;
  }

  public boolean isConst() {
    return isConst;
  }

  @Override
  public ConstructorElement getSymbol() {
    return typeSymbol;
  }

  public void setConstructor(DartExpression newConstructor) {
    constructor = becomeParentOf(newConstructor);
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.typeSymbol = (ConstructorElement) symbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      constructor = becomeParentOf(v.accept(constructor));
      v.acceptWithInsertRemove(this, getArgs());
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    constructor.accept(visitor);
    visitor.visit(getArgs());
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitNewExpression(this);
  }
}
