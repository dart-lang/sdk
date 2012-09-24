// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.Type;

import java.util.Set;

public interface FieldElement extends Element {
  boolean isStatic();

  void setType(Type type);

  MethodElement getGetter();

  MethodElement getSetter();

  /**
   * @return the inferred {@link Type} of this constant, may be <code>null</code> if not set yet.
   */
  Type getConstantType();

  /**
   * @return {@link Element}s overridden by this {@link MethodElement}.
   */
  Set<Element> getOverridden();
}
