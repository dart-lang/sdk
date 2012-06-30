// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.FieldNodeElement;

/**
 * Represents a single field within a field definition.
 */
public class DartField extends DartClassMember<DartIdentifier> {

  private DartExpression value;
  private FieldNodeElement element;
  private DartMethodDefinition accessor;

  public DartField(DartIdentifier name, Modifiers modifiers, DartMethodDefinition accessor,
                   DartExpression value) {
    super(name, modifiers);
    this.accessor = becomeParentOf(accessor);
    this.value = becomeParentOf(value);
  }

  public void setValue(DartExpression value) {
    this.value = becomeParentOf(value);
  }

  public DartExpression getValue() {
    return value;
  }

  public void setAccessor(DartMethodDefinition accessor) {
    this.accessor = becomeParentOf(accessor);
  }

  public DartMethodDefinition getAccessor() {
    return accessor;
  }

  @Override
  public FieldNodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (FieldNodeElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(accessor, visitor);
    safelyVisitChild(value, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitField(this);
  }
}
