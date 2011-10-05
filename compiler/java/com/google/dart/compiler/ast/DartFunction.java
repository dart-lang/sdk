// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart function.
 */
public class DartFunction extends DartNode {

  private final List<DartParameter> params;
  private DartBlock body;
  private DartTypeNode returnTypeNode;

  public DartFunction(List<DartParameter> arguments, DartBlock body, DartTypeNode returnTypeNode) {
    this.params = becomeParentOf(arguments);
    this.body = becomeParentOf(body);
    this.returnTypeNode = becomeParentOf(returnTypeNode);
  }

  public void addParam(DartParameter param) {
    params.add(param);
  }

  public DartBlock getBody() {
    return body;
  }

  public List<DartParameter> getParams() {
    return params;
  }

  public DartTypeNode getReturnTypeNode() {
    return returnTypeNode;
  }

  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      v.acceptWithInsertRemove(this, params);
      if (body != null) {
        body = becomeParentOf(v.accept(body));
      }
      if (returnTypeNode != null) {
        returnTypeNode = becomeParentOf(v.accept(returnTypeNode));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    visitor.visit(params);
    if (body != null) {
      body.accept(visitor);
    }
    if (returnTypeNode != null) {
      returnTypeNode.accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitFunction(this);
  }
}
