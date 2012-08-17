// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

  /**
   * @return "normal" parameter types, i.e. required, does not include "named".
   */
  List<Type> getParameterTypes();

  /**
   * Return the class element corresponding to the interface Function.
   */
  @Override
  ClassElement getElement();

  Type getRest();

  boolean hasRest();

  /**
   * @return "optional" parameter types.
   */
  Map<String, Type> getOptionalParameterTypes();
  
  /**
   * @return "named" parameter types.
   */
  Map<String, Type> getNamedParameterTypes();
}
