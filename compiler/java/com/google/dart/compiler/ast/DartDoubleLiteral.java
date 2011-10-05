// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart double literal value.
 */
public class DartDoubleLiteral extends DartLiteral {

  public static DartDoubleLiteral get(double x) {
    return new DartDoubleLiteral(x);
  }

  private final double value;

  private DartDoubleLiteral(double value) {
    this.value = value;
  }

  public double getValue() {
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
    return visitor.visitDoubleLiteral(this);
  }
}
