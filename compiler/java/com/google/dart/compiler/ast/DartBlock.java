// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart statement block.
 */
public class DartBlock extends DartStatement {

  private final List<DartStatement> stmts;

  public DartBlock(List<DartStatement> statements) {
    this.stmts = becomeParentOf(statements);
  }

  public List<DartStatement> getStatements() {
    return stmts;
  }

  @Override
  public boolean isAbruptCompletingStatement() {
    for (DartStatement stmt : stmts) {
      if (stmt.isAbruptCompletingStatement()) {
        return true;
      }
    }
    return false;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      v.acceptWithInsertRemove(this, stmts);
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    visitor.visit(stmts);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitBlock(this);
  }
}
