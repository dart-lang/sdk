// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      key = becomeParentOf(v.accept(key));
      value = becomeParentOf(v.accept(value));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    key.accept(visitor);
    value.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitMapLiteralEntry(this);
  }
}
