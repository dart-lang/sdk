// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.VariableElement;

/**
 * Represents a single variable declaration in a {@link DartVariableStatement}.
 */
public class DartVariable extends DartDeclaration<DartIdentifier> {

  private VariableElement element;

  private DartExpression value;

  public DartVariable(DartIdentifier name, DartExpression value) {
    super(name);
    this.value = becomeParentOf(value);
  }

  public String getVariableName() {
    return getName().getName();
  }

  @Override
  public VariableElement getElement() {
    return element;
  }

  public DartExpression getValue() {
    return value;
  }

  @Override
  public void setElement(Element element) {
    this.element = (VariableElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    if (value != null) {
      value.accept(visitor);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitVariable(this);
  }
}
