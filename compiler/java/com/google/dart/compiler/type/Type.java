// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.Element;

import java.util.List;

/**
 * Common supertype of all types.
 */
public interface Type {
  /**
   * Performs the substitution [arguments[i]/parameters[i]]this.
   * The notation is known from this lambda calculus rule:
   * (lambda x.e0)e1 -> [e1/x]e0.
   * <p>See {@link TypeVariable} for a motivation for this method.
   */
  Type subst(List<Type> arguments, List<Type> parameters);

  Element getElement();

  TypeKind getKind();
  
  /**
   * @return the {@link TypeQuality}, not <code>null</code>.
   */
  TypeQuality getQuality();
}
