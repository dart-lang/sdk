// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the #source directive.
 */
public class DartSourceDirective extends DartDirective {
  private DartStringLiteral sourceUri;

  public DartSourceDirective(DartStringLiteral sourceUri) {
    this.sourceUri = becomeParentOf(sourceUri);
  }

  public DartStringLiteral getSourceUri() {
    return sourceUri;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      sourceUri = becomeParentOf(v.accept(sourceUri));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    sourceUri.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitSourceDirective(this);
  }
}
