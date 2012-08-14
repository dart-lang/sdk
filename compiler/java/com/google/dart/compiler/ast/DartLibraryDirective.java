// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the library directive.
 */
public class DartLibraryDirective extends DartDirective {
  private DartExpression name;

  public DartLibraryDirective(DartExpression name) {
    this.name = becomeParentOf(name);
  }

  public DartExpression getName() {
    return name;
  }

  public String getLibraryName() {
    if (name == null) {
      return null;
    } else if (name instanceof DartStringLiteral) {
      // TODO(brianwilkerson) Remove this case once the obsolete format is no longer supported.
      return ((DartStringLiteral) name).getValue();
    } else {
      return name.toSource();
    }
  }

  public boolean isObsoleteFormat() {
    // TODO(brianwilkerson) Remove this method once the obsolete format is no longer supported.
    return name instanceof DartStringLiteral;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(name, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitLibraryDirective(this);
  }
}
