// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.MethodElement;

import java.util.List;
import java.util.Map;

/**
 * Function type representation. A function type may correspond to method,
 * constructor, or function in which case its element is the corresponding
 * {@link MethodElement}. Otherwise, the function type can correspond to a named
 * function-type alias or variable type, in which case its element is the class
 * element of the Dart interface Function.
 */
public interface FunctionType extends Type {
  Type getReturnType();

  List<? extends Type> getParameterTypes();

  /**
   * Return the class element corresponding to the interface Function.
   */
  @Override
  ClassElement getElement();

  Type getRest();

  boolean hasRest();

  Map<String, Type> getNamedParameterTypes();

  List<TypeVariable> getTypeVariables();
}
