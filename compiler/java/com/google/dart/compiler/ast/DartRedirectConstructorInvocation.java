// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.ConstructorNodeElement;
import com.google.dart.compiler.resolver.Element;

import java.util.List;

/**
 * Redirected constructor invocation AST node.
 */
public class DartRedirectConstructorInvocation extends DartInvocation {

  private DartIdentifier name;
  private ConstructorNodeElement element;

  public DartRedirectConstructorInvocation(DartIdentifier name, List<DartExpression> args) {
    super(args);
    this.name = becomeParentOf(name);
  }

  public DartIdentifier getName() {
    return name;
  }

  @Override
  public void setElement(Element element) {
    this.element = (ConstructorNodeElement) element;
  }

  @Override
  public ConstructorNodeElement getElement() {
    return element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(name, visitor);
    visitor.visit(getArguments());
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitRedirectConstructorInvocation(this);
  }
}
