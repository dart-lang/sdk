// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart boolean literal value.
 */
public class DartBooleanLiteral extends DartLiteral {

  public static DartBooleanLiteral get(boolean value) {
    return new DartBooleanLiteral(value);
  }

  private final boolean value;

  private DartBooleanLiteral(boolean value) {
    this.value = value;
  }

  public boolean getValue() {
    return value;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitBooleanLiteral(this);
  }
}
