// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.type.Type;

/**
 * Represents a type parameter in a class or interface declaration.
 */
public class DartTypeParameter extends DartDeclaration<DartIdentifier> {

  private DartTypeNode bound;
  private Type type;

  public DartTypeParameter(DartIdentifier name, DartTypeNode bound) {
    super(name);
    this.bound = becomeParentOf(bound);
  }

  public DartTypeNode getBound() {
    return bound;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    if (bound != null) {
      bound.accept(visitor);
    }
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitTypeParameter(this);
  }

  @Override
  public Type getType() {
    return type;
  }

  @Override
  public void setType(Type type) {
    this.type = type;
  }
  
  @Override
  public Element getElement() {
    return getName().getElement();
  }
}
