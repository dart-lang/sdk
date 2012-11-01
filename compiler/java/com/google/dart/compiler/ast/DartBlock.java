// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart statement block.
 */
public class DartBlock extends DartStatement {

  private final NodeList<DartStatement> statements = NodeList.create(this);

  public DartBlock(List<DartStatement> statements) {
    if (statements != null && !statements.isEmpty()) {
      this.statements.addAll(statements);
    }
  }

  public List<DartStatement> getStatements() {
    return statements;
  }

  @Override
  public boolean isAbruptCompletingStatement() {
    for (DartStatement stmt : statements) {
      if (stmt.isAbruptCompletingStatement()) {
        return true;
      }
    }
    return false;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    statements.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitBlock(this);
  }
}
