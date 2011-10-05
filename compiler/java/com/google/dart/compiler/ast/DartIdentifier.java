// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.Element;

/**
 * Represents a Dart identifier expression.
 */
public class DartIdentifier extends DartExpression implements ElementReference {

  private final String targetName;
  private Element targetSymbol;
  private DartExpression normalizedNode = this;
  private Element referencedElement;

  public DartIdentifier(String targetName) {
    assert targetName != null;
    this.targetName = targetName;
  }

  public DartIdentifier(DartIdentifier original) {
    this.targetName = original.targetName;
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
  public Element getSymbol() {
    return targetSymbol;
  }

  @Override
  public boolean isAssignable() {
    return true;
  }

  public String getTargetName() {
    return targetName;
  }

  public Element getTargetSymbol() {
    return targetSymbol;
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.targetSymbol = (Element) symbol;
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
    return visitor.visitIdentifier(this);
  }

  @Override
  public void setReferencedElement(Element element) {
    referencedElement = element;
  }

  @Override
  public Element getReferencedElement() {
    return referencedElement;
  }
}
