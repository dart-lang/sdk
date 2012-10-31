// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the "part of" directive.
 */
public class DartPartOfDirective extends DartDirective {
  private final int ofOffset;
  private final DartExpression name;

  public DartPartOfDirective(int ofOffset, DartExpression name) {
    this.ofOffset = ofOffset;
    this.name = becomeParentOf(name);
  }

  public int getOfOffset() {
    return ofOffset;
  }

  public DartExpression getName() {
    return name;
  }

  public String getLibraryName() {
    return name == null ? null : name.toSource();
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(name, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitPartOfDirective(this);
  }
}
