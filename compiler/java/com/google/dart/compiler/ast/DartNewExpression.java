// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.ConstructorNodeElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.type.Type;

import java.util.List;

/**
 * Represents a Dart 'new' expression.
 */
public class DartNewExpression extends DartInvocation {

  private DartNode constructor;
  private ConstructorNodeElement element;
  private final boolean isConst;

  public DartNewExpression(DartNode constructor, List<DartExpression> args, boolean isConst) {
    super(args);
    this.constructor = becomeParentOf(constructor);
    this.isConst = isConst;
  }

  public DartNode getConstructor() {
    return constructor;
  }

  @Override
  public Type getType() {
    return constructor.getType();
  }

  public boolean isConst() {
    return isConst;
  }

  @Override
  public ConstructorNodeElement getElement() {
    return element;
  }

  public void setConstructor(DartExpression newConstructor) {
    constructor = becomeParentOf(newConstructor);
  }

  @Override
  public void setElement(Element element) {
    this.element = (ConstructorNodeElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(constructor, visitor);
    visitor.visit(getArguments());
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitNewExpression(this);
  }
}
