// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.FunctionAliasElement;

import java.util.List;

class FunctionAliasTypeImplementation extends InterfaceTypeImplementation
    implements FunctionAliasType {

  FunctionAliasTypeImplementation(FunctionAliasElement element, List<? extends Type> arguments) {
    super(element, arguments);
  }

  @Override
  public TypeKind getKind() {
    return TypeKind.FUNCTION_ALIAS;
  }

  @Override
  public FunctionAliasElement getElement() {
    return (FunctionAliasElement) super.getElement();
  }

  @Override
  public FunctionAliasType subst(List<? extends Type> arguments, List<? extends Type> parameters) {
    if (arguments.isEmpty() && parameters.isEmpty()) {
      return this;
    }
    List<Type> substitutedArguments = Types.subst(getArguments(), arguments, parameters);
    return new FunctionAliasTypeImplementation(getElement(), substitutedArguments);
  }
}
