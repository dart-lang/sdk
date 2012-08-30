// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(sourceUri, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitSourceDirective(this);
  }
}
