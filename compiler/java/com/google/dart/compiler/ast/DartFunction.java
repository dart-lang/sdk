// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart function.
 */
public class DartFunction extends DartNode {

  private final NodeList<DartParameter> parameters = NodeList.create(this);
  private final int parametersCloseParen;
  private DartBlock body;
  private DartTypeNode returnTypeNode;

  public DartFunction(List<DartParameter> parameters, int parametersCloseParen, DartBlock body, DartTypeNode returnTypeNode) {
    this.parameters.addAll(parameters);
    this.parametersCloseParen = parametersCloseParen;
    this.body = becomeParentOf(body);
    this.returnTypeNode = becomeParentOf(returnTypeNode);
  }

  public DartBlock getBody() {
    return body;
  }

  public List<DartParameter> getParameters() {
    return parameters;
  }
  
  public int getParametersCloseParen() {
    return parametersCloseParen;
  }

  public DartTypeNode getReturnTypeNode() {
    return returnTypeNode;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    parameters.accept(visitor);
    safelyVisitChild(body, visitor);
    safelyVisitChild(returnTypeNode, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitFunction(this);
  }
}
