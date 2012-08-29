// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.MethodNodeElement;

import java.util.Collections;
import java.util.List;

/**
 * Represents a Dart method definition.
 */
public class DartMethodDefinition extends DartClassMember<DartExpression> {

  protected DartFunction function;
  private MethodNodeElement element;

  public static DartMethodDefinition create(DartExpression name,
                                            DartFunction function,
                                            Modifiers modifiers,
                                            List<DartInitializer> initializers) {
    if (initializers == null) {
      return new DartMethodDefinition(name, function, modifiers);
    } else {
      return new DartMethodWithInitializersDefinition(name, function, modifiers,
                                                      initializers);
    }
  }

  public static DartMethodDefinition create(DartExpression name,
                                            DartFunction function,
                                            Modifiers modifiers,
                                            DartTypeNode redirectedTypeName,
                                            DartIdentifier redirectedConstructorName) {
    if (redirectedTypeName == null) {
      return new DartMethodDefinition(name, function, modifiers);
    } else {
      return new DartMethodWithRedirectionDefinition(name, function, modifiers, redirectedTypeName,
                                                     redirectedConstructorName);
    }
  }

  private DartMethodDefinition(DartExpression name, DartFunction function, Modifiers modifiers) {
    super(name, modifiers);
    this.function = becomeParentOf(function);
  }

  public DartFunction getFunction() {
    return function;
  }

  @Override
  public MethodNodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (MethodNodeElement) element;
  }

  public List<DartInitializer> getInitializers() {
    return Collections.emptyList();
  }

  public DartTypeNode getRedirectedTypeName() {
    return null;
  }

  public DartIdentifier getRedirectedConstructorName() {
    return null;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(function, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitMethodDefinition(this);
  }

  private static class DartMethodWithInitializersDefinition extends DartMethodDefinition {

    private final NodeList<DartInitializer> initializers = NodeList.create(this);

    DartMethodWithInitializersDefinition(DartExpression name,
                                         DartFunction function,
                                         Modifiers modifiers,
                                         List<DartInitializer> initializers) {
      super(name, function, modifiers);
      this.initializers.addAll(initializers);
    }

    @Override
    public List<DartInitializer> getInitializers() {
      return initializers;
    }

    @Override
    public void visitChildren(ASTVisitor<?> visitor) {
      super.visitChildren(visitor);
      initializers.accept(visitor);
    }
  }

  private static class DartMethodWithRedirectionDefinition extends DartMethodDefinition {
    private DartTypeNode redirectedTypeName;
    private DartIdentifier redirectedConstructorName;

    DartMethodWithRedirectionDefinition(DartExpression name,
                                         DartFunction function,
                                         Modifiers modifiers,
                                         DartTypeNode redirectedTypeName,
                                         DartIdentifier redirectedConstructorName) {
      super(name, function, modifiers);
      this.redirectedTypeName = becomeParentOf(redirectedTypeName);
      this.redirectedConstructorName = becomeParentOf(redirectedConstructorName);
    }

    @Override
    public DartTypeNode getRedirectedTypeName() {
      return redirectedTypeName;
    }

    @Override
    public DartIdentifier getRedirectedConstructorName() {
      return redirectedConstructorName;
    }

    @Override
    public void visitChildren(ASTVisitor<?> visitor) {
      super.visitChildren(visitor);
      safelyVisitChild(redirectedTypeName, visitor);
      safelyVisitChild(redirectedConstructorName, visitor);
    }
  }
}
