// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.FunctionAliasType;
import com.google.dart.compiler.type.FunctionType;

/**
 * A function type alias.
 */
public interface FunctionAliasElement extends ClassElement {
  @Override
  FunctionAliasType getType();

  FunctionType getFunctionType();

  void setFunctionType(FunctionType functionType);
}
