// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.Type;

import java.util.List;

public interface MethodElement extends Element, EnclosingElement {
  boolean isConstructor();

  boolean isStatic();

  List<VariableElement> getParameters();

  Type getReturnType();

  FunctionType getFunctionType();
}
