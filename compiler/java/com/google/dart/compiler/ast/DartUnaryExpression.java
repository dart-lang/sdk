// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.MethodNodeElement;

/**
 * Represents a Dart unary expression.
 */
public class DartUnaryExpression extends DartExpression {

  private final Token operator;
  private final int operatorOffset;
  private DartExpression arg;
  private final boolean isPrefix;
  private MethodNodeElement element;

  public DartUnaryExpression(Token operator, int operatorOffset, DartExpression arg, boolean isPrefix) {
    assert operator.isUnaryOperator() || operator == Token.SUB || operator == Token.CONDITIONAL;
    this.operator = operator;
    this.operatorOffset = operatorOffset;
    this.arg = becomeParentOf(arg);
    this.isPrefix = isPrefix;
  }

  public DartExpression getArg() {
    return arg;
  }

  public Token getOperator() {
    return operator;
  }

  public int getOperatorOffset() {
    return operatorOffset;
  }

  public boolean isPrefix() {
    return isPrefix;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(arg, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitUnaryExpression(this);
  }

  @Override
  public MethodNodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (MethodNodeElement) element;
  }
}
