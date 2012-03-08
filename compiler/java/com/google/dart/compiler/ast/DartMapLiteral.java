// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart map literal value.
 */
public class DartMapLiteral extends DartTypedLiteral {

  private final NodeList<DartMapLiteralEntry> entries = NodeList.create(this);

  public DartMapLiteral(boolean isConst, List<DartTypeNode> typeArguments,
      List<DartMapLiteralEntry> entries) {
    super(isConst, typeArguments);
    this.entries.addAll(entries);
  }

  public List<DartMapLiteralEntry> getEntries() {
    return entries;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    entries.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitMapLiteral(this);
  }
}
