// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.NodeElement;

/**
 * Represents a Dart property access expression (a.b).
 */
public class DartPropertyAccess extends DartExpression {

  private DartNode qualifier;
  private DartIdentifier name;

  public DartPropertyAccess(DartNode qualifier, DartIdentifier name) {
    this.qualifier = becomeParentOf(qualifier);
    this.name = becomeParentOf(name);
  }

  @Override
  public boolean isAssignable() {
    return true;
  }

  public String getPropertyName() {
    return name.getName();
  }

  public DartIdentifier getName() {
    return name;
  }

  public DartNode getQualifier() {
    return qualifier;
  }

  public void setName(DartIdentifier newName) {
    name = becomeParentOf(newName);
  }

  @Override
  public void setElement(Element element) {
    name.setElement(element);
  }

  @Override
  public NodeElement getElement() {
    return name.getElement();
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    qualifier.accept(visitor);
    name.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitPropertyAccess(this);
  }
}
