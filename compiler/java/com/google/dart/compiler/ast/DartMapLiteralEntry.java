// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents an entry in a Dart map literal value.
 */
public class DartMapLiteralEntry extends DartNode {

  private DartExpression key;
  private DartExpression value;

  public DartMapLiteralEntry(DartExpression key, DartExpression value) {
    this.key = becomeParentOf(key);
    this.value = becomeParentOf(value);
  }

  public DartExpression getKey() {
    return key;
  }

  public DartExpression getValue() {
    return value;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(key, visitor);
    safelyVisitChild(value, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitMapLiteralEntry(this);
  }
}
