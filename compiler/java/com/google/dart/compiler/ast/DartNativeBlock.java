// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;


/**
 * Unofficial Dart native block for built in native invocations.
 */
public class DartNativeBlock extends DartBlock {

  public DartNativeBlock() {
    super(null);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitNativeBlock(this);
  }
}
