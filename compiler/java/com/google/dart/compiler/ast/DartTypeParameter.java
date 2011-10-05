// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;

/**
 * Represents a type parameter in a class or interface declaration.
 */
public class DartTypeParameter extends DartDeclaration<DartIdentifier> {

  private DartTypeNode bound;

  public DartTypeParameter(DartIdentifier name, DartTypeNode bound) {
    super(name);
    this.bound = becomeParentOf(bound);
  }

  public DartTypeNode getBound() {
    return bound;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (bound != null) {
        bound = becomeParentOf(v.accept(bound));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (bound != null) {
      bound.accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitTypeParameter(this);
  }

  @Override
  public Element getSymbol() {
    return null;
  }
}
