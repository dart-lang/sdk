// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'try/catch' statement.
 */
public class DartTryStatement extends DartStatement {

  private DartBlock tryBlock;
  private final NodeList<DartCatchBlock> catchBlocks = NodeList.create(this);
  private DartBlock finallyBlock;

  public DartTryStatement(DartBlock tryBlock, List<DartCatchBlock> catchBlocks,
      DartBlock finallyBlock) {
    this.tryBlock = becomeParentOf(tryBlock);
    this.catchBlocks.addAll(catchBlocks);
    this.finallyBlock = becomeParentOf(finallyBlock);
  }

  public List<DartCatchBlock> getCatchBlocks() {
    return catchBlocks;
  }

  public DartBlock getFinallyBlock() {
    return finallyBlock;
  }

  public DartBlock getTryBlock() {
    return tryBlock;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(tryBlock, visitor);
    catchBlocks.accept(visitor);
    safelyVisitChild(finallyBlock, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitTryStatement(this);
  }
}
