// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Method invocation AST node. The name of the method must not be null. The receiver is an
 * expression, super, or a classname.
 * <p>
 * {@link DartMethodInvocation} may be created at the parsing time not only for invocation of actual
 * method, but also for invocation of function object in some object. For example:
 * 
 * <pre>
 *  class A {
 *    Function run;
 *  }
 *  test(A a) {
 *    a.run();
 *  }
 * </pre>
 */
public class DartMethodInvocation extends DartInvocation {

  private DartExpression target;
  private boolean isCascade;
  private DartIdentifier functionName;

  public DartMethodInvocation(DartExpression target,
      boolean isCascade,
      DartIdentifier functionName,
      List<DartExpression> args) {
    super(args);
    functionName.getClass(); // Quick null-check.
    this.target = becomeParentOf(target);
    this.isCascade = isCascade;
    this.functionName = becomeParentOf(functionName);
  }

  @Override
  public DartExpression getTarget() {
    return target;
  }

  public DartExpression getRealTarget() {
    if (isCascade) {
      DartNode ancestor = getParent();
      while (!(ancestor instanceof DartCascadeExpression)) {
        if (ancestor == null) {
          return target;
        }
        ancestor = ancestor.getParent();
      }
      return ((DartCascadeExpression) ancestor).getTarget();
    }
    return target;
  }

  public String getFunctionNameString() {
    return functionName.getName();
  }

  public boolean isCascade() {
    return isCascade;
  }

  public DartIdentifier getFunctionName() {
    return functionName;
  }

  public void setFunctionName(DartIdentifier newName) {
    newName.getClass(); // Quick null-check.
    functionName = becomeParentOf(newName);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(target, visitor);
    safelyVisitChild(functionName, visitor);
    visitor.visit(getArguments());
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitMethodInvocation(this);
  }
}
