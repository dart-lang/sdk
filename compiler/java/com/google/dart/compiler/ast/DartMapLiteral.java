// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart map literal value.
 */
public class DartMapLiteral extends DartTypedLiteral {

  private final List<DartMapLiteralEntry> entries;

  public DartMapLiteral(boolean isConst, List<DartTypeNode> typeArguments,
      List<DartMapLiteralEntry> entries) {
    super(isConst, typeArguments);
    this.entries = becomeParentOf(entries);
  }

  public List<DartMapLiteralEntry> getEntries() {
    return entries;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      super.traverse(v, ctx);
      v.acceptWithInsertRemove(this, entries);
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    super.visitChildren(visitor);
    visitor.visit(entries);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitMapLiteral(this);
  }
}
