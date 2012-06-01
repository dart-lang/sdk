// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartExpression;

public interface VariableElement extends Element {
  FieldElement getParameterInitializerElement();

  boolean isNamed();

  DartExpression getDefaultValue();
}
