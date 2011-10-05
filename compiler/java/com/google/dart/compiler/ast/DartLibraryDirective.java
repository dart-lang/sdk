// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the #library directive.
 */
public class DartLibraryDirective extends DartDirective {
  private DartStringLiteral name;

  public DartLibraryDirective(DartStringLiteral name) {
    this.name = becomeParentOf(name);
  }

  public DartStringLiteral getName() {
    return name;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      name = becomeParentOf(v.accept(name));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    name.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitLibraryDirective(this);
  }
}
