// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

public interface ConstructorElement extends MethodElement {
  /**
   * Returns the type of the instances created by this constructor. Note
   * that a constructor in a class may be a default implementation of
   * an interface's constructor.
   */
  ClassElement getConstructorType();
}
