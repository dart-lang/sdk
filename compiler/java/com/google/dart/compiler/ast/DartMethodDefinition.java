// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.MethodElement;

import java.util.Collections;
import java.util.List;

/**
 * Represents a Dart method definition.
 */
public class DartMethodDefinition extends DartClassMember<DartExpression> {

  protected DartFunction function;
  private MethodElement element;
  private DartMethodDefinition normalizedNode = this;
  private final List<DartTypeParameter> typeParameters;

  public static DartMethodDefinition create(DartExpression name,
                                            DartFunction function,
                                            Modifiers modifiers,
                                            List<DartInitializer> initializers,
                                            List<DartTypeParameter> typeParameters) {
    if (initializers == null) {
      return new DartMethodDefinition(name, function, modifiers, typeParameters);
    } else {
      return new DartMethodWithInitializersDefinition(name, function, modifiers, initializers);
    }
  }

  private DartMethodDefinition(DartExpression name, DartFunction function, Modifiers modifiers,
                               List<DartTypeParameter> typeParameters) {
    super(name, modifiers);
    this.function = becomeParentOf(function);
    this.typeParameters = typeParameters;
  }

  public DartFunction getFunction() {
    return function;
  }

  @Override
  public MethodElement getSymbol() {
    return element;
  }

  @Override
  public void setSymbol(Symbol symbol) {
    element = (MethodElement) symbol;
  }

  public void setNormalizedNode(DartMethodDefinition normalizedNode) {
    normalizedNode.setSourceInfo(this);
    this.normalizedNode = normalizedNode;
  }

  @Override
  public DartMethodDefinition getNormalizedNode() {
    return normalizedNode;
  }

  public List<DartInitializer> getInitializers() {
    return Collections.emptyList();
  }

  public List<DartTypeParameter> getTypeParameters() {
    return typeParameters;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      function = becomeParentOf(v.accept(function));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    super.visitChildren(visitor);
    function.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitMethodDefinition(this);
  }

  private static class DartMethodWithInitializersDefinition extends DartMethodDefinition {

    private final List<DartInitializer> initializers;

    DartMethodWithInitializersDefinition(DartExpression name,
                                         DartFunction function,
                                         Modifiers modifiers,
                                         List<DartInitializer> initializers) {
      super(name, function, modifiers, null);
      this.initializers = becomeParentOf(initializers);
    }

    @Override
    public List<DartInitializer> getInitializers() {
      return initializers;
    }

    @Override
    public void traverse(DartVisitor v, DartContext ctx) {
      if (v.visit(this, ctx)) {
        function = becomeParentOf(v.accept(function));
        v.acceptWithInsertRemove(this, initializers);
      }
      v.endVisit(this, ctx);
    }

    @Override
    public void visitChildren(DartPlainVisitor<?> visitor) {
      super.visitChildren(visitor);
      visitor.visit(initializers);
      if (getTypeParameters() != null) {
        visitor.visit(getTypeParameters());
      }
    }
  }
}
