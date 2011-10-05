// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.TypeVariableElement;

import java.util.Iterator;
import java.util.List;

/**
 * Default implementation of {@link TypeVariable}.
 */
class TypeVariableImplementation extends AbstractType implements TypeVariable {
  private final TypeVariableElement element;

  public TypeVariableImplementation(TypeVariableElement element) {
    this.element = element;
  }

  @Override
  public TypeVariableElement getElement() {
    return element;
  }

  @Override
  public TypeVariableElement getTypeVariableElement() {
    return getElement();
  }

  @Override
  public String toString() {
    Element owner = element.getDeclaringElement();
    if (owner == null) {
      return element.getName();
    } else {
      return owner.getName() + "." + element.getName();
    }
  }

  @Override
  public Type subst(List<? extends Type> arguments, List<? extends Type> parameters) {
    Iterator<? extends Type> itA = arguments.iterator();
    Iterator<? extends Type> itP = parameters.iterator();
    while (itA.hasNext() && itP.hasNext()) {
      Type argument = itA.next();
      Type parameter = itP.next();
      if (equals(parameter)) {
        return argument;
      }
    }

    // O(1) check to assert arguments and parameters are of same size.
    assert itA.hasNext() == itP.hasNext() :
      "arguments: " + arguments + " parameters: " + parameters;
    return this;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof TypeVariable) {
      TypeVariable other = (TypeVariable) obj;
      return element.equals(other.getElement());
    }
    return false;
  }

  @Override
  public TypeKind getKind() {
    return TypeKind.VARIABLE;
  }
}
