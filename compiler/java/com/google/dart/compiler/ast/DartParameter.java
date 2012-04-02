// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.base.Preconditions;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.VariableElement;

import java.util.List;

/**
 * Represents a Dart function parameter.
 */
public class DartParameter extends DartDeclaration<DartExpression> {

  private VariableElement element;
  private DartTypeNode typeNode;
  private final NodeList<DartParameter> functionParameters;
  private DartExpression defaultExpr;
  private final Modifiers modifiers;

  public DartParameter(DartExpression name,
                       DartTypeNode typeNode,
                       List<DartParameter> functionParameters,
                       DartExpression defaultExpr,
                       Modifiers modifiers) {
    super(name);
    Preconditions.checkArgument(name instanceof DartIdentifier
      || name instanceof DartPropertyAccess, "name");
    this.typeNode = becomeParentOf(typeNode);
    if (functionParameters != null) {
      this.functionParameters = NodeList.create(this);
      this.functionParameters.addAll(functionParameters);
    } else {
      this.functionParameters = null;
    }
    this.defaultExpr = becomeParentOf(defaultExpr);
    this.modifiers = modifiers;
  }

  public DartExpression getDefaultExpr() {
    return defaultExpr;
  }

  public String getParameterName() {
    // TODO(fabiomfv) remove instanceof (http://b/issue?id=4729144)
    if (getName() instanceof DartIdentifier) {
      return ((DartIdentifier)getName()).getName();
    }
    return ((DartPropertyAccess)getName()).getPropertyName();
  }

  @Override
  public VariableElement getElement() {
    return element;
  }

  public List<DartParameter> getFunctionParameters() {
    return functionParameters;
  }

  public DartTypeNode getTypeNode() {
    return typeNode;
  }

  public Modifiers getModifiers() {
    return modifiers;
  }

  public DartNode getQualifier() {
    if (getName() instanceof DartPropertyAccess) {
      return ((DartPropertyAccess)getName()).getQualifier();
    }
    return null;
  }

  @Override
  public void setElement(Element element) {
    this.element = (VariableElement) element;
  }

  public void setTypeNode(DartTypeNode typeNode) {
    this.typeNode = becomeParentOf(typeNode);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    if (typeNode != null) {
      typeNode.accept(visitor);
    }
    if (defaultExpr != null) {
      defaultExpr.accept(visitor);
    }
    if (functionParameters != null) {
      functionParameters.accept(visitor);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitParameter(this);
  }
}
