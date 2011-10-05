// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.FunctionAliasElement;

import java.util.List;

/**
 * Named function-type alias AST node.
 */
public class DartFunctionTypeAlias extends DartDeclaration<DartIdentifier> implements HasSymbol {

  private DartTypeNode returnTypeNode;
  private final List<DartParameter> parameters;
  private FunctionAliasElement element;
  private final List<DartTypeParameter> typeParameters;

  public DartFunctionTypeAlias(DartIdentifier name, DartTypeNode returnTypeNode,
                               List<DartParameter> parameters,
                               List<DartTypeParameter> typeParameters) {
    super(name);
    this.returnTypeNode = becomeParentOf(returnTypeNode);
    this.parameters = becomeParentOf(parameters);
    this.typeParameters = becomeParentOf(typeParameters);
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
  public FunctionAliasElement getSymbol() {
    return element;
  }

  public void setReturnTypeNode(DartTypeNode newReturnType) {
    returnTypeNode = becomeParentOf(newReturnType);
  }

  @Override
  public void setSymbol(Symbol symbol) {
    element = (FunctionAliasElement) symbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (returnTypeNode != null) {
        returnTypeNode = becomeParentOf(v.accept(returnTypeNode));
      }
      v.acceptWithInsertRemove(this, parameters);
      v.acceptWithInsertRemove(this, typeParameters);
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (returnTypeNode != null) {
      returnTypeNode.accept(visitor);
    }
    visitor.visit(parameters);
    visitor.visit(typeParameters);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitFunctionTypeAlias(this);
  }
}
