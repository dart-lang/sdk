// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.SuperElement;

/**
 * Represents a Dart 'super' expression.
 */
public class DartSuperExpression extends DartExpression {

  private SuperElement targetSymbol;

  public static DartSuperExpression get() {
    return new DartSuperExpression();
  }

  private DartSuperExpression() {
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.targetSymbol = (SuperElement) symbol;
  }

  @Override
  public SuperElement getSymbol() {
    return targetSymbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    v.visit(this, ctx);
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitSuperExpression(this);
  }
}
