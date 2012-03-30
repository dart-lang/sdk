// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.FunctionAliasElement;

import java.util.List;

/**
 * Named function-type alias AST node.
 */
public class DartFunctionTypeAlias extends DartDeclaration<DartIdentifier> {

  private DartTypeNode returnTypeNode;
  private final NodeList<DartParameter> parameters = NodeList.create(this);
  private final NodeList<DartTypeParameter> typeParameters = NodeList.create(this);
  private FunctionAliasElement element;

  public DartFunctionTypeAlias(DartIdentifier name, DartTypeNode returnTypeNode,
                               List<DartParameter> parameters,
                               List<DartTypeParameter> typeParameters) {
    super(name);
    this.returnTypeNode = becomeParentOf(returnTypeNode);
    this.parameters.addAll(parameters);
    this.typeParameters.addAll(typeParameters);
  }

  public List<DartParameter> getParameters() {
    return parameters;
  }

  public DartTypeNode getReturnTypeNode() {
    return returnTypeNode;
  }

  public List<DartTypeParameter> getTypeParameters() {
    return typeParameters;
  }

  @Override
  public FunctionAliasElement getElement() {
    return element;
  }

  public void setReturnTypeNode(DartTypeNode newReturnType) {
    returnTypeNode = becomeParentOf(newReturnType);
  }

  @Override
  public void setElement(Element element) {
    this.element = (FunctionAliasElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    if (returnTypeNode != null) {
      returnTypeNode.accept(visitor);
    }
    parameters.accept(visitor);
    typeParameters.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitFunctionTypeAlias(this);
  }
}
