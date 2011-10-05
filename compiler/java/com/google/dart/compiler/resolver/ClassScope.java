// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.InterfaceType;

/**
 * Lexical scope corresponding to a class body.
 */
class ClassScope extends Scope {
  private final ClassElement classElement;

  ClassScope(ClassElement classElement, Scope parent) {
    super(classElement.getName(), parent);
    this.classElement = classElement;
  }

  @Override
  public Element declareElement(String name, Element element) {
    throw new AssertionError("not supported yet");
  }

  @Override
  public Element findElement(String name) {
    Element element = super.findElement(name);
    if (element != null) {
      return element;
    }
    InterfaceType superclass = classElement.getSupertype();
    if (superclass != null) {
      InterfaceType.Member member = superclass.lookupMember(name);
      if (member != null) {
        return member.getElement();
      }
    }
    for (InterfaceType supertype : classElement.getInterfaces()) {
      InterfaceType.Member member = supertype.lookupMember(name);
      if (member != null) {
        return member.getElement();
      }
    }
    return null;
  }

  @Override
  public Element findLocalElement(String name) {
    return Elements.findElement(classElement, name);
  }
}
