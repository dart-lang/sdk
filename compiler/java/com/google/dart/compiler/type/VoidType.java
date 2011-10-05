// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.Elements;

import java.util.List;

/**
 * Implementation of "void". There is no public interface for this class as Type already exposes
 * all the functionality needed.
 */
class VoidType extends AbstractType {
  @Override
  public Type subst(List<? extends Type> arguments, List<? extends Type> parameters) {
    return this;
  }

  @Override
  public TypeKind getKind() {
    return TypeKind.VOID;
  }

  @Override
  public Element getElement() {
    return Elements.voidElement();
  }

  @Override
  public String toString() {
    return "void";
  }

  @Override
  public boolean equals(Object other) {
    return other instanceof VoidType;
  }

  @Override
  public int hashCode() {
    return VoidType.class.hashCode();
  }
}
