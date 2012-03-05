// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'null' literal value.
 */
public class DartNullLiteral extends DartLiteral {

  public static DartNullLiteral get() {
    return new DartNullLiteral();
  }

  private DartNullLiteral() {
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitNullLiteral(this);
  }
}
