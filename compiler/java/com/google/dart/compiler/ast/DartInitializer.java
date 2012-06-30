// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a constructor initializer expression.
 */
public class DartInitializer extends DartNode {

  private DartIdentifier name;
  private DartExpression value;

  public DartInitializer(DartIdentifier name, DartExpression value) {
    this.name = becomeParentOf(name);
    this.value = becomeParentOf(value);
  }

  public String getInitializerName() {
    if (name == null) {
      return null;
    }
    return name.getName();
  }

  public DartIdentifier getName() {
    return name;
  }

  public DartExpression getValue() {
    return value;
  }

  /**
   * Determines if initializer is an invocation.
   * @return true if initializer is either super or redirected constructor invocation.
   */
  public boolean isInvocation() {
    return name == null;
  }

  public void setName(DartIdentifier newName) {
    name = becomeParentOf(newName);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(name, visitor);
    safelyVisitChild(value, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitInitializer(this);
  }
}
