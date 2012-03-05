// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.Element;

/**
 * Represents a single variable declaration in a {@link DartVariableStatement}.
 */
public class DartVariable extends DartDeclaration<DartIdentifier> implements HasSymbol {

  private Element symbol;

  private DartExpression value;

  public DartVariable(DartIdentifier name, DartExpression value) {
    super(name);
    this.value = becomeParentOf(value);
  }

  public String getVariableName() {
    return getName().getTargetName();
  }

  @Override
  public Element getSymbol() {
    return symbol;
  }

  public DartExpression getValue() {
    return value;
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.symbol = (Element) symbol;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    if (value != null) {
      value.accept(visitor);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitVariable(this);
  }
}
