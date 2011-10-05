// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.DynamicElement;

import java.util.List;

/**
 * Type of untyped expressions.
 */
public interface DynamicType extends FunctionAliasType, TypeVariable, FunctionType {

  @Override
  DynamicType subst(List<? extends Type> arguments, List<? extends Type> parameters);

  @Override
  public DynamicElement getElement();

  @Override
  public DynamicType asRawType();
}
