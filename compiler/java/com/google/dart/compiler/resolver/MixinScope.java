// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

/**
 * Lexical scope corresponding to a mixin.
 */
class MixinScope extends Scope {
  private final ClassElement mixinElement;

  MixinScope(ClassElement mixinElement) {
    super(mixinElement.getName(), mixinElement.getLibrary(), null);
    this.mixinElement = mixinElement;
  }

  @Override
  public Element declareElement(String name, Element element) {
    throw new AssertionError("not supported yet");
  }

  @Override
  public Element findLocalElement(String name) {
    return Elements.findElement(mixinElement, name);
  }
}
