// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

/**
 * Lexical scope corresponding to a mixin.
 */
class MixinScope extends Scope {
  private final ClassElement classElement;

  MixinScope(ClassElement classElement, Scope parent) {
    super(classElement.getName(), parent.getLibrary(), parent);
    this.classElement = classElement;
  }

  @Override
  public Element declareElement(String name, Element element) {
    throw new AssertionError("not supported yet");
  }

  @Override
  public Element findLocalElement(String name) {
    return Elements.findElement(classElement, name);
  }
}
