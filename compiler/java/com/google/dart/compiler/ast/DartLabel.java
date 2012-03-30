// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.LabelElement;

/**
 * Represents a Dart statement label.
 */
public class DartLabel extends DartStatement {

  // Not visited. Similar to DartDeclaration, but DartDeclaration shouldn't be
  // a statement or an expression.
  private DartIdentifier label;

  private LabelElement element;

  private DartStatement statement;

  public DartLabel(DartIdentifier label, DartStatement statement) {
    this.label = becomeParentOf(label);
    this.statement = becomeParentOf(statement);
  }

  public DartIdentifier getLabel() {
    return label;
  }

  public String getName() {
    return label.getName();
  }

  public DartStatement getStatement() {
    return statement;
  }

  @Override
  public LabelElement getElement() {
    return element;
  }

  public void setLabel(DartIdentifier newLabel) {
    label = newLabel;
  }

  @Override
  public void setElement(Element element) {
    this.element = (LabelElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    label.accept(visitor);
    if (statement != null) {
      statement.accept(visitor);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitLabel(this);
  }
}
