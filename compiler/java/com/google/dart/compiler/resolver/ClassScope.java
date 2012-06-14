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
    super(classElement.getName(), parent.getLibrary(), parent);
    this.classElement = classElement;
  }

  @Override
  public Element declareElement(String name, Element element) {
    throw new AssertionError("not supported yet");
  }

  @Override
  public Element findElement(LibraryElement inLibrary, String name) {
    Element element = super.findElement(inLibrary, name);
    if (element != null) {
      return element;
    }
    InterfaceType superclass = classElement.getSupertype();
    if (superclass != null) {
      Element enclosing = superclass.getElement().getEnclosingElement();
      ClassElement superclassElement = superclass.getElement();
      if (superclassElement != classElement) {
        ClassScope scope = new ClassScope(superclassElement,
                                          new Scope("library", (LibraryElement) enclosing));
        element = scope.findElement(inLibrary, name);
        switch (ElementKind.of(element)) {
          case TYPE_VARIABLE:
            return null;
          case NONE:
            break;
          default:
            return element;
        }
      }
    }
    for (InterfaceType supertype : classElement.getInterfaces()) {
      Element enclosing = supertype.getElement().getEnclosingElement();
      ClassElement superclassElement = supertype.getElement();
      if (superclassElement != classElement) {
        ClassScope scope = new ClassScope(superclassElement,
                                          new Scope("library", (LibraryElement) enclosing));
        element = scope.findElement(inLibrary, name);
        if (element != null) {
          return element;
        }
      }
    }
    return null;
  }

  @Override
  public Element findLocalElement(String name) {
    return Elements.findElement(classElement, name);
  }
}
