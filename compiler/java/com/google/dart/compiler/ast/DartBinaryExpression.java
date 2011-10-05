// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.Element;

/**
 * Represents a Dart binary expression.
 */
public class DartBinaryExpression extends DartExpression implements ElementReference {

  private final Token op;
  private DartExpression arg1;
  private DartExpression arg2;
  private DartExpression normalizedNode = this;
  private Element referencedElement;

  public DartBinaryExpression(Token op, DartExpression arg1, DartExpression arg2) {
    assert op.isBinaryOperator() : op;

    this.op = op;
    this.arg1 = becomeParentOf(arg1);
    this.arg2 = becomeParentOf(arg2);
  }

  public DartExpression getArg1() {
    return arg1;
  }

  public DartExpression getArg2() {
    return arg2;
  }

  public Token getOperator() {
    return op;
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
      if (op.isAssignmentOperator()) {
        arg1 = becomeParentOf(v.acceptLvalue(arg1));
      } else {
        arg1 = becomeParentOf(v.accept(arg1));
      }
      arg2 = becomeParentOf(v.accept(arg2));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    arg1.accept(visitor);
    arg2.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitBinaryExpression(this);
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
