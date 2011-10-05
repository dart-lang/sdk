// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.math.BigInteger;

/**
 * Represents a Dart integer literal value.
 */
public class DartIntegerLiteral extends DartLiteral {

  public static DartIntegerLiteral get(BigInteger x) {
    return new DartIntegerLiteral(x);
  }

  public static DartIntegerLiteral one() {
    return new DartIntegerLiteral(BigInteger.ONE);
  }

  private final BigInteger value;

  private DartIntegerLiteral(BigInteger value) {
    this.value = value;
  }

  public BigInteger getValue() {
    return value;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    v.visit(this, ctx);
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitIntegerLiteral(this);
  }
}
