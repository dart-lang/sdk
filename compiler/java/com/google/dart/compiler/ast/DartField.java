// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.FieldElement;

/**
 * Represents a single field within a field definition.
 */
public class DartField extends DartClassMember<DartIdentifier> {

  private DartExpression value;
  private FieldElement element;
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
  public FieldElement getSymbol() {
    return element;
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.element = (FieldElement) symbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (getValue() != null) {
        setValue(v.accept(getValue()));
      }
      if (getAccessor() != null) {
        setAccessor(v.accept(getAccessor()));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    super.visitChildren(visitor);
    if (getAccessor() != null) {
      getAccessor().accept(visitor);
    }
    if (getValue() != null) {
      getValue().accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitField(this);
  }

  @Override
  public int computeHash() {
    // TODO(jgw): Remove this altogether in fixing b/5324113.

    // DartField doesn't include the type-node, so we directly return the hash of its type, which
    // is all that matters for the purposes of dependency-tracking.
    DartFieldDefinition def = (DartFieldDefinition) getParent();
    DartTypeNode typeNode = def.getTypeNode();
    if (typeNode == null) {
      // Use 0 to represent an untyped field.
      return 0;
    }
    return typeNode.computeHash();
  }
}
