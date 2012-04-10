// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file
package com.google.dart.compiler.ast;

/**
 * This node is created by the parser when it cannot find a proper identifier token in the input
 * stream.  The token might not have been consumed, or was a reserved word, so the name of the
 * identifier is left blank.
 */
public class DartSyntheticErrorIdentifier extends DartIdentifier {

  private final String tokenString;

  public DartSyntheticErrorIdentifier() {
    super("");
    this.tokenString = "";
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitSyntheticErrorIdentifier(this);
  }

  public String getTokenString() {
    return tokenString;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }
}
