// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;

/**
 * Represention of a type variable.
 *
 * <p>For example, in {@code class Foo<T> { ... }}, {@code T} is a
 * type variable.
 */
public interface TypeVariableElement extends Element {
  // Workaround JDK 6 bug. Should @Override getType().
  TypeVariable getTypeVariable();

  Type getBound();

  void setBound(Type bound);

  Element getDeclaringElement();
}
