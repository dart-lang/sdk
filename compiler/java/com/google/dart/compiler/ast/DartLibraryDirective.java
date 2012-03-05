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
  public void visitChildren(ASTVisitor<?> visitor) {
    name.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitLibraryDirective(this);
  }
}
