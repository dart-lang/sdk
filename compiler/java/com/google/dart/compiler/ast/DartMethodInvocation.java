// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.Symbol;

import java.util.List;

/**
 * Method invocation AST node. The name of the method must not be
 * null. The receiver is an expression, super, or a classname.
 */
public class DartMethodInvocation extends DartInvocation {

  private DartExpression target;
  private DartIdentifier functionName;
  private Symbol targetSymbol;

  public DartMethodInvocation(DartExpression target,
                              DartIdentifier functionName,
                              List<DartExpression> args) {
    super(args);
    functionName.getClass(); // Quick null-check.
    this.target = becomeParentOf(target);
    this.functionName = becomeParentOf(functionName);
  }

  @Override
  public DartExpression getTarget() {
    return target;
  }

  public String getFunctionNameString() {
    return functionName.getTargetName();
  }

  public DartIdentifier getFunctionName() {
    return functionName;
  }

  public void setFunctionName(DartIdentifier newName) {
    newName.getClass(); // Quick null-check.
    functionName = becomeParentOf(newName);
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.targetSymbol = symbol;
  }

  public Symbol getTargetSymbol() {
    return targetSymbol;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      target = becomeParentOf(v.accept(target));
      functionName = becomeParentOf(v.accept(functionName));
      functionName.getClass(); // Quick null-check.
      v.acceptWithInsertRemove(this, getArgs());
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    target.accept(visitor);
    functionName.accept(visitor);
    visitor.visit(getArgs());
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitMethodInvocation(this);
  }
}
