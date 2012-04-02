// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.MethodElement;

/**
 * Represents a Dart 'function' expression.
 */
public class DartFunctionExpression extends DartExpression {

  // Not visited. Similar to DartDeclaration, but DartDeclaration shouldn't be
  // a statement or an expression.
  private DartIdentifier name;

  private final boolean isStmt;
  private MethodElement element;
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
    return name.getName();
  }

  public DartIdentifier getName() {
    return name;
  }

  @Override
  public MethodElement getElement() {
    return element;
  }

  public boolean isStatement() {
    return isStmt;
  }

  public void setName(DartIdentifier newName) {
    name = becomeParentOf(newName);
  }

  @Override
  public void setElement(Element element) {
    this.element = (MethodElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    if (name != null) {
      name.accept(visitor);
    }
    function.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitFunctionExpression(this);
  }
}
