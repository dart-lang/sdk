// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.Type;

import java.util.List;
import java.util.Set;

public interface MethodElement extends Element, EnclosingElement {
  boolean isConstructor();

  boolean isStatic();
  
  boolean hasBody();

  List<VariableElement> getParameters();

  Type getReturnType();

  FunctionType getFunctionType();

  /**
   * @return {@link Element}s overridden by this {@link MethodElement}.
   */
  Set<Element> getOverridden();
}
