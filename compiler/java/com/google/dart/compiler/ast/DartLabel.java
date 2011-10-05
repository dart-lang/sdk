// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;

/**
 * Represents a Dart statement label.
 */
public class DartLabel extends DartStatement implements HasSymbol {

  // Not visited. Similar to DartDeclaration, but DartDeclaration shouldn't be
  // a statement or an expression.
  private DartIdentifier label;

  private Symbol symbol;

  private DartStatement statement;

  public DartLabel(DartIdentifier label, DartStatement statement) {
    this.label = becomeParentOf(label);
    this.statement = becomeParentOf(statement);
  }

  public DartIdentifier getLabel() {
    return label;
  }

  public String getName() {
    return label.getTargetName();
  }

  public DartStatement getStatement() {
    return statement;
  }

  @Override
  public Symbol getSymbol() {
    return symbol;
  }

  public void setLabel(DartIdentifier newLabel) {
    label = newLabel;
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.symbol = symbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      statement = becomeParentOf(v.accept(statement));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (statement != null) {
      statement.accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitLabel(this);
  }
}
