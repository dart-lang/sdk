// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.base.Preconditions;
import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.VariableElement;

import java.util.List;

/**
 * Represents a Dart function parameter.
 */
public class DartParameter extends DartDeclaration<DartExpression> implements HasSymbol {

  private VariableElement symbol;
  private DartTypeNode typeNode;
  private List<DartParameter> functionParameters;
  private DartExpression defaultExpr;
  private DartParameter normalizedNode = this;
  private final Modifiers modifiers;

  public DartParameter(DartExpression name,
                       DartTypeNode typeNode,
                       List<DartParameter> functionParameters,
                       DartExpression defaultExpr,
                       Modifiers modifiers) {
    super(name);
    Preconditions.checkArgument((name instanceof DartIdentifier)
      || (name instanceof DartPropertyAccess), "name");
    this.typeNode = becomeParentOf(typeNode);
    this.functionParameters = becomeParentOf(functionParameters);
    this.defaultExpr = becomeParentOf(defaultExpr);
    this.modifiers = modifiers;
  }

  public DartExpression getDefaultExpr() {
    return defaultExpr;
  }

  public String getParameterName() {
    // TODO(fabiomfv) remove instanceof (http://b/issue?id=4729144)
    if (getName() instanceof DartIdentifier) {
      return ((DartIdentifier)getName()).getTargetName();
    }
    return ((DartPropertyAccess)getName()).getPropertyName();
  }

  @Override
  public VariableElement getSymbol() {
    return symbol;
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

  public void setNormalizedNode(DartParameter normalizedNode) {
    normalizedNode.setSourceInfo(this);
    this.normalizedNode = normalizedNode;
  }

  @Override
  public DartParameter getNormalizedNode() {
    return normalizedNode;
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.symbol = (VariableElement) symbol;
  }

  public void setTypeNode(DartTypeNode typeNode) {
    this.typeNode = becomeParentOf(typeNode);
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (typeNode != null) {
        typeNode = becomeParentOf(v.accept(typeNode));
      }
      if (defaultExpr != null) {
        defaultExpr = becomeParentOf(v.accept(defaultExpr));
      }
      if (functionParameters != null) {
        v.acceptWithInsertRemove(this, functionParameters);
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (typeNode != null) {
      typeNode.accept(visitor);
    }
    if (defaultExpr != null) {
      defaultExpr.accept(visitor);
    }
    visitor.visit(functionParameters);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitParameter(this);
  }
}
