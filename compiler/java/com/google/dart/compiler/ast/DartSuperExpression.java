// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.SuperElement;

/**
 * Represents a Dart 'super' expression.
 */
public class DartSuperExpression extends DartExpression {

  private SuperElement element;

  public static DartSuperExpression get() {
    return new DartSuperExpression();
  }

  private DartSuperExpression() {
  }

  @Override
  public void setElement(Element element) {
    this.element = (SuperElement) element;
  }

  @Override
  public SuperElement getElement() {
    return element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitSuperExpression(this);
  }
}
