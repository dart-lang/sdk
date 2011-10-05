// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.Element;

/**
 * Represents a Dart property access expression (a.b).
 */
public class DartPropertyAccess extends DartExpression {

  private DartNode qualifier;
  private DartIdentifier name;
  private DartExpression normalizedNode = this;

  public DartPropertyAccess(DartNode qualifier, DartIdentifier name) {
    this.qualifier = becomeParentOf(qualifier);
    this.name = becomeParentOf(name);
  }

  @Override
  public boolean isAssignable() {
    return true;
  }

  public String getPropertyName() {
    return name.getTargetName();
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
  public void setSymbol(Symbol symbol) {
    name.setSymbol(symbol);
  }

  public Element getTargetSymbol() {
    return name.getTargetSymbol();
  }

  public void setNormalizedNode(DartExpression normalizedNode) {
    normalizedNode.setSourceInfo(this);
    this.normalizedNode = normalizedNode;
  }

  @Override
  public DartExpression getNormalizedNode() {
    return normalizedNode;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      qualifier = becomeParentOf(v.accept(qualifier));
      name = becomeParentOf(v.accept(name));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    qualifier.accept(visitor);
    name.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitPropertyAccess(this);
  }
}
