// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'continue' statement.
 */
public class DartContinueStatement extends DartGotoStatement {

  public DartContinueStatement(DartIdentifier label) {
    super(label);
  }

  @Override
  public boolean isAbruptCompletingStatement() {
    return true;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    DartIdentifier label = getLabel();
    if (v.visit(this, ctx) && label != null) {
      label = becomeParentOf(v.accept(label));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitContinueStatement(this);
  }
}
