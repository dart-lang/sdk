// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'try/catch' statement.
 */
public class DartTryStatement extends DartStatement {

  private DartBlock tryBlock;
  private List<DartCatchBlock> catchBlocks;
  private DartBlock finallyBlock;

  public DartTryStatement(DartBlock tryBlock, List<DartCatchBlock> catchBlocks,
      DartBlock finallyBlock) {
    this.tryBlock = becomeParentOf(tryBlock);
    this.catchBlocks = becomeParentOf(catchBlocks);
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
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      tryBlock = becomeParentOf(v.accept(tryBlock));
      v.acceptWithInsertRemove(this, catchBlocks);
      if (finallyBlock != null) {
        finallyBlock = becomeParentOf(v.accept(finallyBlock));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    tryBlock.accept(visitor);
    visitor.visit(catchBlocks);
    if (finallyBlock != null) {
      finallyBlock.accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitTryStatement(this);
  }
}
