// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the #resource directive.
 */
public class DartResourceDirective extends DartDirective {
  private DartStringLiteral resourceUri;

  public DartResourceDirective(DartStringLiteral resourceUri) {
    this.resourceUri = becomeParentOf(resourceUri);
  }

  public DartStringLiteral getResourceUri() {
    return resourceUri;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(resourceUri, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitResourceDirective(this);
  }
}
