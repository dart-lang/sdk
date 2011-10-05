// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.Element;

/**
 * Represents a Dart unary expression.
 */
public class DartUnaryExpression extends DartExpression implements ElementReference {

  private final Token operator;
  private DartExpression arg;
  private final boolean isPrefix;
  private DartExpression normalizedNode = this;
  private Element referencedElement;

  public DartUnaryExpression(Token operator, DartExpression arg, boolean isPrefix) {
    assert operator.isUnaryOperator() || operator == Token.SUB;

    this.isPrefix = isPrefix;
    this.operator = operator;
    this.arg = becomeParentOf(arg);
  }

  public DartExpression getArg() {
    return arg;
  }

  public Token getOperator() {
    return operator;
  }

  public boolean isPrefix() {
    return isPrefix;
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
      if (operator.isCountOperator()) {
        arg = becomeParentOf(v.acceptLvalue(getArg()));
      } else {
        arg = becomeParentOf(v.accept(getArg()));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    arg.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitUnaryExpression(this);
  }

  @Override
  public Element getReferencedElement() {
    return referencedElement;
  }

  @Override
  public void setReferencedElement(Element referencedElement) {
    this.referencedElement = referencedElement;
  }
}
