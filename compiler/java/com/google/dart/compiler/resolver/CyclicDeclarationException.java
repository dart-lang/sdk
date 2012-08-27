// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

/**
 * Exception thrown if a cycle is detected in the supertype graph of a class or interface.
 */
public class CyclicDeclarationException extends Exception {
  private static final long serialVersionUID = 1L;

  private final ClassElement element;

  public CyclicDeclarationException(ClassElement element) {
    super(element.getName());
    this.element = element;
  }

  public ClassElement getElement() {
    return element;
  }
}
